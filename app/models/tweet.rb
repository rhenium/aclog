class Tweet < ActiveRecord::Base
  belongs_to :user
  has_many :favorites, -> { order("favorites.id") }, dependent: :delete_all
  has_many :retweets, -> { order("retweets.id") }, dependent: :delete_all

  has_many :favoriters, ->  {order("favorites.id") }, through: :favorites, source: :user
  has_many :retweeters, -> { order("retweets.id") }, through: :retweets, source: :user

  scope :recent, -> { where("tweets.tweeted_at > ?", Time.zone.now - 3.days) }
  scope :reacted, -> {where("tweets.favorites_count > 0 OR tweets.retweets_count > 0") }
  scope :not_protected, -> { includes(:user).where(users: {protected: false}) }
  scope :max_id, -> id { where("tweets.id <= ?", id.to_i) if id }
  scope :since_id, -> id { where("tweets.id > ?", id.to_i) if id }

  scope :page, -> page, count { offset((page - 1) * count) }

  scope :order_by_id, -> { order("tweets.id DESC") }
  scope :order_by_favorites, -> { order("tweets.favorites_count DESC") }
  scope :order_by_retweets, -> { order("tweets.retweets_count DESC") }
  scope :order_by_reactions, -> { order("COALESCE(tweets.favorites_count, 0) + COALESCE(tweets.retweets_count, 0) DESC") }

  scope :of, -> user { where(user: user) if user }
  scope :favorited_by, -> user { joins(:favorites).where(favorites: {user_id: user.id}) }
  scope :retweeted_by, -> user { joins(:retweets).where(retweets: {user_id: user.id}) }
  scope :discovered_by, -> user {
    un = "SELECT favorites.tweet_id FROM favorites WHERE favorites.user_id = #{user.id}" +
         " UNION " +
         "SELECT retweets.tweet_id FROM retweets WHERE retweets.user_id = #{user.id}"

    joins("INNER JOIN (#{un}) m ON m.tweet_id = tweets.id")
  }

  def self.delete_from_id(id)
    return {} if id.is_a?(Array) && id.size == 0
    begin
      # counter_cache の無駄を省くために delete_all で
      deleted_tweets = Tweet.where("id IN (?)", id).delete_all
      if deleted_tweets > 0
        deleted_favorites = Favorite.where("tweet_id IN (?)", id).delete_all
        deleted_retweets = Retweet.where("tweet_id IN (?)", id).delete_all
      end

      unless id.is_a?(Integer) && deleted_tweets == 1
        deleted_retweets = Retweet.where("id IN (?)", id).destroy_all.size # counter_cache
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

  def self.list(params, options = {})
    params[:page] ||= "1" if options[:force_page]

    count = params[:count].to_i
    count = Settings.tweets.count_default unless (1..Settings.tweets.count_max) === count

    ret = limit(count)

    if params[:page]
      ret.page(params[:page].to_i, count)
    else
      ret.max_id(params[:max_id]).since_id(params[:since_id])
    end
  end

end

