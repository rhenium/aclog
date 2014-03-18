class Favorite < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  def self.create_from_json(json)
    tweet = Tweet.create_from_json(json[:target_object])
    user = User.create_from_json(json[:source])

    transaction do
      favorite = Favorite.create!(tweet: tweet, user: user)
      tweet.update_reactions_count(favorites_count: 1, json: json[:target_object])

      favorite
    end
  rescue ActiveRecord::RecordNotUnique => e
    logger.debug("Duplicate favorite: #{user.id} => #{tweet.id}")
    self.where(tweet: tweet, user: user).first
  end

  def self.destroy_from_json(json)
    transaction do
      deleted_count = self.where(user_id: json[:source][:id], tweet_id: json[:target_object][:id]).delete_all
      if deleted_count > 0
        Tweet.find(json[:target_object][:id]).update_reactions_count(favorites_count: -1, json: json[:target_object])
      end
    end
  end
end
