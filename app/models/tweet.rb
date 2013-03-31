class Tweet < ActiveRecord::Base
  belongs_to :user
  has_many :favorites, :dependent => :delete_all
  has_many :retweets, :dependent => :delete_all

  scope :recent, -> do
    where("tweeted_at > ?", Time.zone.now - 3.days)
  end

  scope :reacted, -> do
    where("favorites_count > 0 OR retweets_count > 0")
  end

  scope :order_by_id, -> do
    order("id DESC")
  end

  scope :order_by_favorites, -> do
    order("favorites_count DESC")
  end

  scope :order_by_retweets, -> do
    order("retweets_count DESC")
  end

  scope :order_by_reactions, -> do
    order("COALESCE(favorites_count, 0) + COALESCE(retweets_count, 0) DESC")
  end

  scope :favorited_by, -> user do
    joins(:favorites).where(:favorites => {:user_id => user.id})
  end

  scope :retweeted_by, -> user do
    joins(:retweets).where(:retweets => {:user_id => user.id})
  end

  scope :discovered_by, -> user do
    joins("INNER JOIN (" +
            "(SELECT favorites.tweet_id FROM favorites WHERE favorites.user_id = #{user.id})" +
          " UNION " +
            "(SELECT retweets.tweet_id FROM retweets WHERE retweets.user_id = #{user.id})" +
          ") AS m ON m.tweet_id = tweets.id")
  end

  def self.cached(id)
    Rails.cache.fetch("tweet/#{id}", :expires_in => 3.hour) do
      where(:id => id).first
    end
  end

  def user
    User.cached(user_id)
  end

  def self.delete_from_id(id)
    begin
      # where(:id => id).destroy_all
      # counter_cache の無駄を省くために delete_all で
      Favorite.delete_all(:tweet_id => id)
      Retweet.delete_all(:tweet_id => id)
      Tweet.delete_all(:id => id)
    rescue
      logger.error("Unknown error while deleting tweet: #{$!}/#{$@}")
    end
  end

  def self.from_hash(hash)
    begin
      create!(:id => hash[:id],
              :text => hash[:text],
              :source => hash[:source],
              :tweeted_at => hash[:tweeted_at],
              :user_id => hash[:user_id])
    rescue ActiveRecord::RecordNotUnique
      logger.debug("Duplicate Tweet: #{hash[:id]}")
    rescue
      logger.error("Unknown error while inserting tweet: #{$!}/#{$@}")
    end
  end
end

