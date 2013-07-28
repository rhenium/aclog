class Retweet < ActiveRecord::Base
  belongs_to :tweet, :counter_cache => true
  belongs_to :user

  def self.from_receiver(msg)
    transaction do
      t = Tweet.from_receiver(msg["tweet"])
      u = User.from_receiver(msg["user"])
      r = self.create!(id: msg["id"],
                       tweet: t,
                       user: u)
      logger.debug("Created Retweet: #{msg["id"]}: #{msg["user"]["id"]} => #{msg["tweet"]["id"]}")
      return r
    end
  rescue ActiveRecord::RecordNotUnique
    logger.debug("Duplicate Retweet: #{msg["id"]}: #{msg["user"]["id"]} => #{msg["tweet"]["id"]}")
    return nil
  rescue => e
    logger.error("Unknown error while inserting retweet: #{e.class}: #{e.message}/#{e.backtrace.join("\n")}")
    return nil
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
