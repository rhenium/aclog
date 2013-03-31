class Favorite < ActiveRecord::Base
  belongs_to :tweet
  counter_culture :tweet
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

  def self.from_hash(hash)
    begin
      create!(:tweet_id => hash[:tweet_id],
              :user_id => hash[:user_id])
      logger.debug("Created Favorite: #{hash[:user_id]} => #{hash[:tweet_id]}")
    rescue ActiveRecord::RecordNotUnique
      logger.debug("Duplicate Favorite: #{hash[:user_id]} => #{hash[:tweet_id]}")
    rescue
      logger.error("Unknown error while inserting favorite: #{$!}/#{$@}")
    end
  end

  def self.from_tweet_object(tweet_object)
    if tweet_object.favoriters.is_a? Array
      tweet_object.favoriters.each do |uid|
        from_hash(:user_id => uid, :tweet_id => tweet_object.id)
      end
    end
  end

  def self.delete_from_hash(hash)
    where(:tweet_id => hash[:tweet_id])
      .where(:user_id => hash[:user_id])
      .destroy_all
  end
end
