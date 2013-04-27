class Retweet < ActiveRecord::Base
  belongs_to :tweet, :counter_cache => true
#  counter_culture :tweet
  belongs_to :user

  def self.from_hash(hash)
    begin
      r = create!(id: hash[:id],
                  tweet_id: hash[:tweet_id],
                  user_id: hash[:user_id])
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
    Tweet.from_tweet_object(status.retweeted_status)
    from_hash(id: status.id,
              user_id: status.user.id,
              tweet_id: status.retweeted_status.id)
  end
end
