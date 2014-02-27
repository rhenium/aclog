class Favorite < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  def self.create_from_json(json)
    tweet = Tweet.create_from_json(json[:target_object])
    user = User.create_from_json(json[:source])

    favorite = Favorite.new(tweet: tweet, user: user)

    transaction do
      favorite.save!
      tweet.update_reactions_count(favorites_count: 1, json: json[:target_object])
    end
  rescue ActiveRecord::RecordNotUnique => e
    logger.debug("Duplicate favorite: #{favorite.user_id} => #{favorite.tweet_id}")
  rescue => e
    logger.error("Failed to create a favorite: #{e.class}: #{e.message}/#{e.backtrace.join("\n")}")
  ensure
    return favorite
  end

  def self.destroy_from_json(json)
    transaction do
      deleted_count = self.where(user_id: json[:source][:id], tweet_id: json[:target_object][:id]).delete_all
      if deleted_count > 0
        Tweet.find(json[:target_object][:id]).update_reactions_count(favorites_count: -1, json: json[:target_object])
      end
    end
  rescue => e
    logger.error("Failed to destroy a favorite: #{e.class}: #{e.message}/#{e.backtrace.join("\n")}")
  end
end
