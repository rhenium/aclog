class Retweet < ActiveRecord::Base
  belongs_to :tweet
  counter_culture :tweet
  belongs_to :user

  scope :order_by_id, -> do
    order("id DESC")
  end

  def user
    User.cached(user_id)
  end

  def tweet
    Tweet.cached(tweet_id)
  end

  def self.from_hash(hash)
    begin
      r = create!(:id => hash[:id],
                  :tweet_id => hash[:tweet_id],
                  :user_id => hash[:user_id])
      logger.debug("Created Retweet: #{hash[:id]}: #{hash[:user_id]} => #{hash[:tweet_id]}")

      return r
    rescue ActiveRecord::RecordNotUnique
      logger.debug("Duplicate Retweet: #{hash[:id]}: #{hash[:user_id]} => #{hash[:tweet_id]}")
    rescue
      logger.error("Unknown error while inserting retweet: #{$!}/#{$@}")
    end
  end

  def self.from_tweet_object(status)
    User.from_user_object(status.user)
    from_hash(:id => status.id,
              :user_id => status.user.id,
              :tweet_id => status.retweeted_status.id)
  end
end
