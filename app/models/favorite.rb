class Favorite < ActiveRecord::Base
  belongs_to :tweet, :counter_cache => true
  belongs_to :user

  scope :order_by_id, -> do
    order("id DESC")
  end

  def user
    User.cached(user_id)
  end

  def tweet
    Tweet.cached(tweet_id)
  end
end
