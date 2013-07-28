class Favorite < ActiveRecord::Base
  belongs_to :tweet, counter_cache: true
  belongs_to :user

  def self.from_receiver(msg)
    transaction do
      t = Tweet.from_receiver(msg["tweet"])
      u = User.from_receiver(msg["user"])
      f = logger.quietly { self.create!(tweet: t, user: u) }
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

  def self.from_tweet_object(tweet_object)
    if tweet_object.favoriters.is_a? Array
      tweet_object.favoriters.reverse.map do |uid|
        from_hash(user_id: uid, tweet_id: tweet_object.id)
      end
    end
  end

  def self.delete_from_receiver(msg)
    where(tweet_id: msg["tweet"]["id"], user_id: msg["user"]["id"]).destroy_all
  end
end
