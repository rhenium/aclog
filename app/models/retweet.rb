class Retweet < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  after_create do
    Tweet.update_counters(self.tweet_id, retweets_count: 1, reactions_count: 1)
  end

  after_destroy do
    Tweet.update_counters(self.tweet_id, retweets_count: -1, reactions_count: -1)
  end

  def self.from_receiver(msg)
    transaction do
      t = Tweet.from_receiver(msg["tweet"])
      u = User.from_receiver(msg["user"])
      r = logger.quietly { t.retweets.create!(id: msg["id"], user: u) }
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
end
