class Tweet < ActiveRecord::Base
  belongs_to :user
  delegate :screen_name, :name, :profile_image_url, to: :user, prefix: true

  belongs_to :in_reply_to, class_name: "Tweet"
  has_many :replies, class_name: "Tweet", foreign_key: "in_reply_to_id"

  has_many :favorites, -> { order("favorites.id") }, dependent: :delete_all
  has_many :retweets, -> { order("retweets.id") }, dependent: :delete_all

  has_many :favoriters, ->  {order("favorites.id") }, through: :favorites, source: :user
  has_many :retweeters, -> { order("retweets.id") }, through: :retweets, source: :user

  scope :recent, ->(days = 3) { where("tweets.id > ?", snowflake_min(Time.zone.now - days.days)) }
  scope :reacted, -> { where.not(reactions_count: 0) }
  scope :not_protected, -> { includes(:user).where(users: {protected: false}) }

  scope :max_id, -> id { where("tweets.id <= ?", id.to_i) if id }
  scope :since_id, -> id { where("tweets.id > ?", id.to_i) if id }
  scope :page, ->(page) { offset((page - 1) * all.limit_value) }

  scope :order_by_id, -> { order(id: :desc) }
  scope :order_by_reactions, -> { order(reactions_count: :desc) }

  scope :favorited_by, -> user { joins(:favorites).where(favorites: {user: user}) }
  scope :retweeted_by, -> user { joins(:retweets).where(retweets: {user: user}) }
  scope :discovered_by, -> user {
    load_count = all.limit_value.to_i + all.offset_value.to_i
    load_count = nil if load_count == 0
    un = [:favorites, :retweets].map {|m| user.__send__(m).select(:tweet_id).order(tweet_id: :desc).limit(load_count).to_sql }.join(") UNION (")

    joins("INNER JOIN ((#{un})) reactions ON reactions.tweet_id = tweets.id")
  }

  def twitter_url
    "https://twitter.com/#{self.user.screen_name}/status/#{self.id}"
  end

  def notify_favorite
    if Settings.notification.enabled
      Notification.notify_favorite(self)
    end
  end

  def self.from_json(msg)
    find_by(id: msg[:id]) || begin
      user = User.from_json(msg[:user])
      create!(id: msg[:id],
              text: extract_entities(msg),
              source: msg[:source],
              tweeted_at: msg[:created_at],
              in_reply_to_id: msg[:in_reply_to_status_id],
              user: user)
    end
  rescue ActiveRecord::RecordNotUnique
    logger.debug("Duplicate Tweet: #{msg[:id]}")
  rescue => e
    logger.error("Unknown error while inserting tweet: #{e.class}: #{e.message}/#{e.backtrace.join("\n")}")
  end

  def self.from_twitter_object(obj)
    tweet = from_json(obj.attrs)
    tweet.update!(favorites_count: obj.favorites_count,
                  retweets_count: obj.retweets_count,
                  reactions_count: obj.favorites_count + obj.retweets_count)
  end

  def self.filter_by_query(query)
    strings = []
    query.gsub!(/"((?:\\"|[^"])*?)"/) {|m| strings << $1; "##{strings.size - 1}" }

    escape_text = -> str do
      str.gsub(/#(\d+)/) { strings[$1.to_i] }
         .gsub("%", "\\%")
         .gsub("*", "%")
         .gsub("_", "\\_")
         .gsub("?", "_")
    end

    parse_condition = ->(scoped, token) do
      p positive = !token.slice!(/^[-!]/)

      where_args = case token
      when /^(?:user|from):([A-Za-z0-9_]{1,20})$/
        u = User.find_by(screen_name: $1)
        uid = u && u.id || -1
        { user_id: uid }
      when /^fav(?:orite)?s?:(\d+)$/
        ["favorites_count >= ?", $1.to_i]
      when /^(?:retweet|rt)s?:(\d+)$/
        ["retweets_count >= ?", $1.to_i]
      when /^(?:sum|(?:re)?act(?:ion)?s?):(\d+)$/
        ["reactions_count >= ?", $1.to_i]
      when /^(?:source|via):(.+)$/
        ["source LIKE ?", escape_text.call($1)]
      when /^text:(.+)$/
        ["text LIKE ?", "%" + escape_text.call($1) + "%"]
      else
        nil
      end

      positive ? scoped.where(where_args) : scoped.where.not(where_args)
    end

    query.scan(/\S+/).inject(self.scoped) {|s, token| parse_condition.call(s, token) }
  end

  private
  def self.extract_entities(json)
    entity_values = json[:entities].values.sort_by {|v| v[:indices].first }

    result = ""
    last_index = entity_values.inject(0) do |last_index, entity|
      result << json[:text][last_index...entity["indices"].first]
      if entity.key?(:url)
        result << entity[:expanded_url]
      else
        result << entity[:text]
      end

      entity[:indices].last
    end
    result << json[:text][last_index..-1]

    result
  end

  def self.snowflake_min(time)
    (time.to_datetime.to_i * 1000 - 1288834974657) << 22
  end
end

