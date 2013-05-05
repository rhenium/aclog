class Retweet < ActiveRecord::Base
  belongs_to :tweet, :counter_cache => true
#  counter_culture :tweet
  belongs_to :user

  def self.from_hash(hash)
    begin
      r = logger.quietly do
        create!(id: hash[:id],
                tweet_id: hash[:tweet_id],
                user_id: hash[:user_id])
      end
      logger.debug("Created Retweet: #{hash[:id]}: #{hash[:user_id]} => #{hash[:tweet_id]}")

      return r
    rescue ActiveRecord::RecordNotUnique
      logger.debug("Duplicate Retweet: #{hash[:id]}: #{hash[:user_id]} => #{hash[:tweet_id]}")
    rescue => e
      logger.error("Unknown error while inserting retweet: #{e.class}: #{e.message}/#{e.backtrace.join("\n")}")
    end
  end

  def self.from_tweet_object(status)
    User.from_user_object(status.user)
    # Tweet.from_tweet_object(status.retweeted_status)
    # TODO: URL format...
    from_hash(id: status.id,
              user_id: status.user.id,
              tweet_id: status.retweeted_status.id)
  end
end
