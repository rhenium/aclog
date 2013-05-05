class Tweet < ActiveRecord::Base
  belongs_to :user
  has_many :favorites, -> { order("favorites.id") }, dependent: :delete_all
  has_many :retweets, -> { order("retweets.id") }, dependent: :delete_all
  has_one :stolen_tweet, ->{ includes(:original) }, dependent: :delete

  has_many :favoriters, ->  {order("favorites.id") }, through: :favorites, source: :user
  has_many :retweeters, -> { order("retweets.id") }, through: :retweets, source: :user
  has_one :original, through: :stolen_tweet, source: :original

  scope :recent, -> { where("tweets.tweeted_at > ?", Time.zone.now - 3.days) }
  scope :reacted, -> {where("tweets.favorites_count > 0 OR tweets.retweets_count > 0") }
  scope :original, -> { includes(:stolen_tweet).where(stolen_tweets: {tweet_id: nil}) }
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
    un = "SELECT favorites.tweet_id, favorites.user_id FROM favorites" +
         " UNION " +
         "SELECT retweets.tweet_id, retweets.user_id FROM retweets"

    joins("INNER JOIN (#{un}) m ON m.tweet_id = tweets.id AND m.user_id = #{user.id}")
  }

  # will be moved
  def notify_favorite
    if [50, 100, 250, 500, 1000].include? favorites.count
      Aclog::Notification.reply_favs(self, favorites.count)
    end
  end

  def self.delete_from_id(id)
    begin
      # counter_cache の無駄を省くために delete_all で
      deleted_tweets = Tweet.delete_all(id: id)
      if deleted_tweets.to_i > 0
        Favorite.delete_all(tweet_id: id)
        Retweet.delete_all(tweet_id: id)
      else
        Retweet.where(id: id).destroy_all # counter_cache
      end

      return id
    rescue
      logger.error("Unknown error while deleting tweet: #{$!}/#{$@}")
    end
  end

  def self.from_hash(hash)
    begin
      logger.quietly do
        t = create!(id: hash[:id],
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
    count = 10 unless (1..100) === count

    ret = limit(count)

    if params[:page]
      ret.page(params[:page].to_i, count)
    else
      ret.max_id(params[:max_id]).since_id(params[:since_id])
    end
  end

end

