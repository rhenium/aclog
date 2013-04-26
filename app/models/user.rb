class User < ActiveRecord::Base
  has_many :tweets, dependent: :delete_all
  has_many :favorites, dependent: :delete_all
  has_many :retweets, dependent: :delete_all

  def self.from_hash(hash)
    begin
      user = where(id: hash[:id]).first || User.new(id: hash[:id])
      orig = user.attributes.dup

      user.screen_name = hash[:screen_name]
      user.name = hash[:name]
      user.profile_image_url = hash[:profile_image_url]
      user.protected = hash[:protected]

      if orig != user.attributes
        user.save!
        user.delete_cache
        logger.debug("User saved: #{user.id}")
      else
        logger.debug("User not changed: #{user.id}")
      end

      return user
    rescue
      logger.error("Unknown error while inserting user: #{$!}/#{$@}")
    end
  end

  def self.from_user_object(user_object)
    from_hash(id: user_object.id,
              screen_name: user_object.screen_name,
              name: user_object.name,
              profile_image_url: user_object.profile_image_url_https,
              protected: user_object.protected)
  end

  def protected?
    protected
  end

  def registered?
    account
  end

  def account
    Account.where(user_id: id).first
  end

  def profile_image_url_original
    profile_image_url.sub(/_normal((?:\.(?:png|jpeg|gif))?)/, "\\1")
  end

  def stats(include_stats_api = false)
    @stats_cache ||= begin
      raise Aclog::Exceptions::UserNotRegistered unless account

      hash = {favorites_count: favorites.count,
              retweets_count: retweets.count,
              tweets_count: tweets.length, # cache: tweets.inject calls "SELECT `tweets`.*"
              favorited_count: 0,
              retweeted_count: 0}

      if include_stats_api
        twitter_user = account.client.user
        if twitter_user
          h = {
            favorites_count: twitter_user.favourites_count,
            listed_count: twitter_user.listed_count,
            followers_count: twitter_user.followers_count,
            tweets_count: twitter_user.statuses_count,
            friends_count: twitter_user.friends_count,
            bio: twitter_user.description
          }
        end
        hash[:stats_api] = h
      end

      tweets.inject(hash) do |hash, m|
        hash[:favorited_count] += m.favorites_count
        hash[:retweeted_count] += m.retweets_count
        hash
      end
    end
  end
end
