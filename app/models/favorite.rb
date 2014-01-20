class Favorite < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  after_create do
    Tweet.update_counters(self.tweet_id, favorites_count: 1, reactions_count: 1)
  end

  after_destroy do
    Tweet.update_counters(self.tweet_id, favorites_count: -1, reactions_count: -1)
  end

  def self.from_json(json)
    tweet = Tweet.from_json(json[:target_object])
    user = User.from_json(json[:source])
    favorite = Favorite.new(tweet: tweet, user: user)
    if favorite.save
      logger.debug("Successfully created a favorite: #{favorite.id}")
    else
      logger.debug("Failed to create a favorite: #{favorite}")
    end

    favorite
  end
end
