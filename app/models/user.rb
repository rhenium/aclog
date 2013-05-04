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

  def stats
    @stats_cache ||= begin
      raise Aclog::Exceptions::UserNotRegistered unless account

      hash = {favorites_count: favorites.count,
              retweets_count: retweets.count,
              tweets_count: tweets.length, # cache: tweets.inject calls "SELECT `tweets`.*"
              favorited_count: 0,
              retweeted_count: 0}

      tweets.inject(hash) do |hash, m|
        hash[:favorited_count] += m.favorites_count
        hash[:retweeted_count] += m.retweets_count
        hash
      end

      OpenStruct.new(hash)
    end
  end

  def count_discovered_by
    merge_count_user(count_by(Favorite), count_by(Retweet))
  end

  def count_discovered_users
    merge_count_user(count_to(Favorite), count_to(Retweet))
  end

  private
  def count_by(klass)
    actions = klass.joins("INNER JOIN (#{tweets.order_by_id.limit(100).to_sql}) m ON tweet_id = m.id")
    actions.inject(Hash.new(0)) {|hash, obj| hash[obj.user_id] += 1; hash }
  end

  def count_to(klass)
    actions = Tweet.joins("INNER JOIN (#{klass.where(user: self).order("id DESC").limit(500).to_sql}) m ON tweets.id = m.tweet_id")
    actions.inject(Hash.new(0)) {|hash, obj| hash[obj.user_id] += 1; hash }
  end

  def merge_count_user(*args)
    ret = {}
    args.map.each_with_index do |o, i|
      o.each do |user_id, count|
        ret[user_id] ||= Array.new(args.size, 0)
        ret[user_id][i] = count
      end
    end
    ret.map(&:flatten).sort_by {|user_id, favorites_count, retweets_count| -(favorites_count + retweets_count) }
  end
end
