class Tweet < ActiveRecord::Base
  belongs_to :user

  belongs_to :in_reply_to, class_name: "Tweet"
  has_many :replies, class_name: "Tweet", foreign_key: "in_reply_to_id"

  has_many :favorites, -> { order("favorites.id") }, dependent: :delete_all
  has_many :retweets, -> { order("retweets.id") }, dependent: :delete_all

  has_many :favoriters, ->  { order("favorites.id") }, through: :favorites, source: :user
  has_many :retweeters, -> { order("retweets.id") }, through: :retweets, source: :user

  scope :eager_load_for_html, -> { eager_load(:user) }

  scope :recent, ->(period = 3.days) { where("tweets.id > ?", snowflake_min(Time.zone.now - period)) }
  scope :reacted, ->(count = nil) { where("reactions_count >= ?", (count || 1).to_i) }
  scope :not_protected, -> { joins(:user).references(:user).where(users: { protected: false }) }
  scope :registered, -> { joins(user: :account).references(:account).merge(Account.active) }

  scope :max_id, -> id { where("tweets.id <= ?", id.to_i) if id }
  scope :since_id, -> id { where("tweets.id > ?", id.to_i) if id }
  scope :page, ->(page, page_per) { limit(page_per).offset((page - 1) * page_per) }

  scope :order_by_id, -> { order(id: :desc) }
  scope :order_by_reactions, -> { order(reactions_count: :desc) }

  scope :favorited_by, ->(user) { joins(:favorites).where(favorites: { user: user }) }
  scope :retweeted_by, ->(user) { joins(:retweets).where(retweets: { user: user }) }
  scope :discovered_by, ->(user) {
    load_count = all.limit_value.to_i + all.offset_value.to_i
    load_count = nil if load_count == 0

    un = [:favorites, :retweets].map {|m|
      user.__send__(m).select(:tweet_id).order(tweet_id: :desc).limit(load_count)
    }.map {|m| "(#{m.to_sql})" }.join(" UNION ")

    joins("INNER JOIN ((#{un})) reactions ON reactions.tweet_id = tweets.id")
  }

  class << self
    def create_from_json(json)
      tweet = transaction do
        self.find_by(id: json[:id]) ||
          self.create!(id: json[:id],
                       text: extract_entities(json),
                       source: json[:source],
                       tweeted_at: json[:created_at],
                       in_reply_to_id: json[:in_reply_to_status_id],
                       user: User.create_from_json(json[:user]))
      end
    rescue ActiveRecord::RecordNotUnique => e
      logger.debug("Duplicate tweet: #{tweet}: #{e.class}") # collector may be threaded
      self.find(json[:id])
    end

    def create_from_twitter_object(obj)
      t = self.create_from_json(obj.attrs)
      t.update_reactions_count(json: obj.attrs)
      t
    end

    def destroy_from_json(json)
      deleted_count = self.delete(json[:delete][:status][:id])

      if deleted_count > 0
        Favorite.where(tweet_id: json[:delete][:status][:id]).delete_all
        Retweet.where(tweet_id: json[:delete][:status][:id]).delete_all
        true
      else
        false
      end
    end

    def import(id, client = nil)
      client ||= Account.random.client

      st = client.status(id)
      tweet = self.create_from_twitter_object(st)
      tweet.update(text: extract_entities(st.attrs),
                   source: st.attrs[:source],
                   in_reply_to_id: (tweet.in_reply_to_id || st.attrs[:in_reply_to_status_id]))

      nt = tweet
      nt = self.create_from_twitter_object(client.status(nt.in_reply_to_id)) while !nt.in_reply_to && nt.in_reply_to_id

      tweet.reload
    end

    def filter_by_query(query)
      strings = []
      query = query.gsub(/"((?:\\"|[^"])*?)"/) {|m| strings << $1; "##{strings.size - 1}" }

      escape_text = -> str do
        str.gsub(/#(\d+)/) { strings[$1.to_i] }
           .gsub("%", "\\%")
           .gsub("*", "%")
           .gsub("_", "\\_")
           .gsub("?", "_")
      end

      parse_condition = ->(scoped, token) do
        positive = !token.slice!(/^[-!]/)

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

      query.scan(/\S+/).inject(self.all) {|s, token| parse_condition.call(s, token) }
    end

    private
    # replace t.co with expanded_url
    def extract_entities(json)
      entity_values = json[:entities].values.flatten.sort_by {|v| v[:indices].first }
      entity_values.select! {|e| e[:url] }

      result = ""
      last_index = entity_values.inject(0) do |last_index, entity|
        result << json[:text][last_index...entity[:indices].first]
        result << entity[:expanded_url]
        entity[:indices].last
      end
      result << json[:text][last_index..-1]

      result
    end

    def snowflake_min(time)
      (time.to_datetime.to_i * 1000 - 1288834974657) << 22
    end
  end

  def twitter_url
    "https://twitter.com/#{self.user.screen_name}/status/#{self.id}"
  end

  def reply_ancestors(max_level = Float::INFINITY)
    nodes = []
    node = self
    level = 0

    while node.in_reply_to && level < max_level
      nodes << (node = node.in_reply_to)
      level += 1
    end
    nodes
  end

  def reply_descendants(max_level = Float::INFINITY)
    nodes = []
    c_nodes = [self]
    level = 0

    while c_nodes.size > 0 && level < max_level
      nodes.concat(c_nodes.map! {|node| node.replies }.flatten!)
      level += 1
    end
    nodes.sort_by {|t| t.id }
  end

  def update_reactions_count(favorites_count: 0, retweets_count: 0, json: {})
    fav_op = favorites_count >= 0 ? "+" : "-"
    rts_op = retweets_count >= 0 ? "+" : "-"
    Tweet.where(id: self.id)
      .update_all("favorites_count = GREATEST(favorites_count #{fav_op} #{favorites_count.abs}, #{(json[:favorite_count] || 0).to_i}), " +
                  "retweets_count = GREATEST(retweets_count #{rts_op} #{retweets_count.abs}, #{(json[:retweet_count] || 0).to_i}), " +
                  "reactions_count = favorites_count + retweets_count")
  end
end
