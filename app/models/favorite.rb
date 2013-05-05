class Favorite < ActiveRecord::Base
  belongs_to :tweet, :counter_cache => true
#  counter_culture :tweet
  belongs_to :user

  def self.from_hash(hash)
    begin
      f = logger.quietly do
        create!(tweet_id: hash[:tweet_id], user_id: hash[:user_id])
      end
      logger.debug("Created Favorite: #{hash[:user_id]} => #{hash[:tweet_id]}")

      return f
    rescue ActiveRecord::RecordNotUnique
      logger.debug("Duplicate Favorite: #{hash[:user_id]} => #{hash[:tweet_id]}")
    rescue => e
      logger.error("Unknown error while inserting favorite: #{e.class}: #{e.message}/#{e.backtrace.join("\n")}")
    end
  end

  def self.from_tweet_object(tweet_object)
    if tweet_object.favoriters.is_a? Array
      tweet_object.favoriters.reverse.map do |uid|
        from_hash(user_id: uid, tweet_id: tweet_object.id)
      end
    end
  end

  def self.delete_from_hash(hash)
    where(tweet_id: hash[:tweet_id], user_id: hash[:user_id]).destroy_all
  end
end
