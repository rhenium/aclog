class Tweet < ActiveRecord::Base
  extend Aclog::Twitter

  belongs_to :user
  has_many :favorites, -> { order("favorites.id") }, dependent: :delete_all
  has_many :retweets, -> { order("retweets.id") }, dependent: :delete_all

  has_many :favoriters, ->  {order("favorites.id") }, through: :favorites, source: :user
  has_many :retweeters, -> { order("retweets.id") }, through: :retweets, source: :user

  scope :recent, ->(days = 3) { where("tweets.id > ?", snowflake(Time.zone.now - days.days)) }
  scope :reacted, -> {where("tweets.favorites_count > 0 OR tweets.retweets_count > 0") }
  scope :not_protected, -> { includes(:user).where(users: {protected: false}) }

  scope :max_id, -> id { where("tweets.id <= ?", id.to_i) if id }
  scope :since_id, -> id { where("tweets.id > ?", id.to_i) if id }
  scope :page, ->(page, count) { offset((page - 1) * count) }

  scope :order_by_id, -> { order("tweets.id DESC") }
  scope :order_by_favorites, -> { order("tweets.favorites_count DESC") }
  scope :order_by_retweets, -> { order("tweets.retweets_count DESC") }
  scope :order_by_reactions, -> { order("COALESCE(tweets.favorites_count, 0) + COALESCE(tweets.retweets_count, 0) DESC") }

  scope :favorited_by, -> user { joins(:favorites).where(favorites: {user: user}) }
  scope :retweeted_by, -> user { joins(:retweets).where(retweets: {user: user}) }
  scope :discovered_by, -> user {
    un = "SELECT favorites.tweet_id FROM favorites WHERE favorites.user_id = #{user.id}" +
         " UNION " +
         "SELECT retweets.tweet_id FROM retweets WHERE retweets.user_id = #{user.id}"

    joins("INNER JOIN (#{un}) m ON m.tweet_id = tweets.id")
  }

  def self.list(params, options = {})
    params[:page] ||= "1" if options[:force_page]

    count = params[:count].to_i
    count = Settings.tweets.count_default unless (1..Settings.tweets.count_max) === count

    ret = limit(count)

    if params[:page]
      ret = ret.page(params[:page].to_i, count)
    else
      ret = ret.max_id(params[:max_id]).since_id(params[:since_id])
    end

    if options[:cache] && options[:cache] > 0
      ret = ret.cache_list(options[:cache])
    end

    ret
  end

  def self.delete_from_id(id)
    return {} if id.is_a?(Array) && id.size == 0
    begin
      # counter_cache の無駄を省くために delete_all で
      deleted_tweets = Tweet.where(id: id).delete_all
      if deleted_tweets > 0
        deleted_favorites = Favorite.where(tweet_id: id).delete_all
        deleted_retweets = Retweet.where(tweet_id: id).delete_all
      end

      unless id.is_a?(Integer) && deleted_tweets == 1
        deleted_retweets = Retweet.where(id: id).destroy_all.size # counter_cache
      end

      return {tweets: deleted_tweets, favorites: deleted_favorites, retweets: deleted_retweets}
    rescue
      logger.error("Unknown error while deleting tweet: #{$!}/#{$@}")
    end
  end

  def self.from_hash(hash)
    begin
      t = logger.quietly do
        create!(id: hash[:id],
                text: hash[:text],
                source: hash[:source],
                tweeted_at: hash[:tweeted_at],
                user_id: hash[:user_id])
      end
      logger.debug("Created Tweet: #{hash[:id]}")

      return t
    rescue ActiveRecord::RecordNotUnique
      logger.debug("Duplicate Tweet: #{hash[:id]}")
    rescue => e
      logger.error("Unknown error while inserting tweet: #{e.class}: #{e.message}/#{e.backtrace.join("\n")}")
    end
  end

  def self.parse_query(query)
    str = query.dup
    strings = []
    str.gsub!(/"((?:\\"|[^"])*?)"/) {|m| strings << $1; "##{strings.size - 1}" }
    groups = []
    while str.sub!(/\(([^()]*?)\)/) {|m| groups << $1; " $#{groups.size - 1} " }; end

    conv = -> s do
      s.scan(/\S+(?: +OR +\S+)*/).map {|co|
        co.split(/ +OR +/).map {|token|
          if /^\$(\d+)$/ =~ token
            conv.call(groups[$1.to_i])
          else
            parse_condition(token, strings)
          end
        }.inject(&:or)
      }.inject(&:and)
    end

    where(conv.call(str))
  end

  private
  def self.parse_condition(token, strings)
    tweets = Tweet.arel_table
    escape_text = -> str do
      str.gsub(/#(\d+)/) { strings[$1.to_i] }
         .gsub("%", "\\%")
         .gsub("*", "%")
         .gsub("_", "\\_")
         .gsub("?", "_")
    end

    positive = token[0] != "-"
    case token
    when /^-?(?:user|from):([A-Za-z0-9_]{1,20})$/
      u = User.find_by(screen_name: $1)
      uid = u && u.id || 0
      tweets[:user_id].__send__(positive ? :eq : :not_eq, uid)
    when /^-?since:(\d{4}(-?)\d{2}\2\d{2})$/
      tweets[:id].__send__(positive ? :gteq : :lt, snowflake(Date.parse($1)))
    when /^-?until:(\d{4}(-?)\d{2}\2\d{2})$/
      tweets[:id].__send__(positive ? :lt : :gteq, snowflake(Date.parse($1) + 1))
    when /^-?favs?:(\d+)$/
      tweets[:favorites_count].__send__(positive ? :gteq : :lt, $1.to_i)
    when /^-?rts?:(\d+)$/
      tweets[:retweets_count].__send__(positive ? :gteq : :lt, $1.to_i)
    when /^-?(?:sum|reactions?):(\d+)$/
      (tweets[:favorites_count] + tweets[:retweets_count]).__send__(positive ? :gteq : :lt, $1.to_i)
    when /^(?:source|via):(.+)$/
      source_text = "<url:%:#{escape_text.call($1).gsub(":", "%3A")}>"
      tweets[:source].__send__(positive ? :matches : :does_not_match, source_text)
    else
      search_text = escape_text.call(positive ? token : token[1..-1])
      tweets[:text].__send__(positive ? :matches : :does_not_match, "%#{search_text}%")
    end
  end

  def self.cache_list(expires_in)
    key = "tweets/#{scoped.to_sql}"
    ids = Rails.cache.read(key)
    unless ids
      ids = pluck(&:id)
      Rails.cache.write(key, ids, expires_in: expires_in)
    end
    Tweet.where(id: ids).order("CASE tweets.id #{ids.each_with_index.map {|m, i| "WHEN #{m} THEN #{i}" }.join(" ")} END")
  end
end

