class Favorite < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  after_create do
    Tweet.update_counters(self.tweet_id, favorites_count: 1, reactions_count: 1)
  end

  after_destroy do
    Tweet.update_counters(self.tweet_id, favorites_count: -1, reactions_count: -1)
  end

  def self.from_receiver(msg)
    transaction do
      t = Tweet.from_receiver(msg["tweet"])
      u = User.from_receiver(msg["user"])
      f = logger.quietly { t.favorites.create!(user: u) }
      logger.debug("Created Favorite: #{msg["user"]["id"]} => #{msg["tweet"]["id"]}")
      return f
    end
  rescue ActiveRecord::RecordNotUnique
    logger.debug("Duplicate Favorite: #{msg["user"]["id"]} => #{msg["tweet"]["id"]}")
    return nil
  rescue => e
    logger.error("Unknown error while inserting favorite: #{e.class}: #{e.message}/#{e.backtrace.join("\n")}")
    return nil
  end

  def self.delete_from_receiver(msg)
    where(tweet_id: msg["tweet"]["id"], user_id: msg["user"]["id"]).destroy_all
  end
end
