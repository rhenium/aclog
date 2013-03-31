class User < ActiveRecord::Base
  has_many :tweets, :dependent => :delete_all
  has_many :favorites, :dependent => :delete_all
  has_many :retweets, :dependent => :delete_all

  def self.cached(identity)
    if identity.is_a?(Fixnum) || identity.is_a?(Bignum)
      Rails.cache.fetch("user/#{identity}", :expires_in => 3.hour) do
        where(:id => identity).first
      end
    elsif identity.is_a?(String)
      if /^[A-Za-z0-9_]{1,15}$/ =~ identity
        uid = Rails.cache.fetch("screen_name/#{identity}", :expires_in => 3.hour) do
          if user = where(:screen_name => identity).first
            user.id
          end
        end

        cached(uid)
      end
    elsif identity.is_a?(NilClass)
      nil
    else
      raise Exception, "Invalid identity: #{identity}"
    end
  end

  def protected?
    protected
  end

  def registered?
    account
  end

  def account
    Account.where(:user_id => id).first
  end

  def profile_image_url_original
    profile_image_url.sub(/_normal((\.(png|jpeg|gif))?)/, "\\1")
  end

  def twitter_user
    if registered?
      account.twitter_user
    else
      raise Exception, "why??"
    end
  end

  def stats
    @stats_cache ||= ->{
      raise Aclog::Exceptions::UserNotRegistered unless account

      tweets.inject(
        {favorites_count: favorites.count,
         retweets_count: retweets.count,
         tweets_count: tweets.length, # cache: tweets.inject calls "SELECT `tweets`.*"
         favorited_count: 0,
         retweeted_count: 0,
         stats_api: account.stats_api}
      ) do |hash, m|
        hash[:favorited_count] += m.favorites_count
        hash[:retweeted_count] += m.retweets_count
        hash
      end
    }.call
  end

  def self.from_hash(hash)
    begin
      rec = find_or_initialize_by(:id => hash[:id])
      rec.screen_name = hash[:screen_name]
      rec.name = hash[:name]
      rec.profile_image_url = hash[:profile_image_url]
      rec.protected = hash[:protected]
      rec.save! if rec.changed?
    rescue
      logger.error("Unknown error while inserting user: #{$!}/#{$@}")
    end
  end

  def self.from_user_object(user_object)
    from_hash(:id => user_object.id,
              :screen_name => user_object.screen_name,
              :name => user_object.name,
              :profile_image_url => user_object.profile_image_url_https,
              :protected => user_object.protected)
  end
end
