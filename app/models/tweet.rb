class Tweet < ActiveRecord::Base
  belongs_to :user
  has_many :favorites, :dependent => :delete_all
  has_many :retweets, :dependent => :delete_all

  scope :recent, -> do
    where("tweeted_at > ?", Time.zone.now - 3.days)
  end

  scope :reacted, -> do
    where("favorites_count > 0 OR retweets_count > 0")
  end

  scope :order_by_id, -> do
    order("id DESC")
  end

  scope :order_by_reactions, -> do
    order("COALESCE(favorites_count, 0) + COALESCE(retweets_count, 0) DESC")
  end

  scope :favorited_by, -> user do
    where("id IN (SELECT tweet_id FROM favorites WHERE user_id = ?)", user.id)
  end

  scope :retweeted_by, -> user do
    where("id IN (SELECT tweet_id FROM retweets WHERE user_id = ?)", user.id)
  end

  scope :discovered_by, -> user do
    where("id IN (" +
          "SELECT tweet_id FROM favorites WHERE user_id = ?" +
          " UNION ALL " +
          "SELECT tweet_id FROM retweets WHERE user_id = ?" +
          ")", user.id, user.id)
  end

  scope :of, -> user do
    where("user_id = ?", user.id)
  end

  def self.cached(id)
    Rails.cache.fetch("tweet/#{id}", :expires_in => 3.hour) do
      where(:id => id).first
    end
  end

  def user
    User.cached(user_id)
  end
end
