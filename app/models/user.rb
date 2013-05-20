class User < ActiveRecord::Base
  has_many :tweets, dependent: :delete_all
  has_many :favorites, dependent: :delete_all
  has_many :retweets, dependent: :delete_all

  def self.from_hash(hash)
    begin
      user = where(id: hash[:id]).first_or_initialize
      orig = user.attributes.dup

      user.screen_name = hash[:screen_name]
      user.name = hash[:name]
      user.profile_image_url = hash[:profile_image_url]
      user.protected = hash[:protected]

      if orig["screen_name"] == user.screen_name &&
         orig["name"] == user.name &&
         orig["profile_image_url"].split(//).reverse.take(36) == user.profile_image_url.split(//).reverse.take(36) &&
         orig["protected"] = user.protected?
        logger.debug("User not changed: #{user.id}")
      else
        user.save!
        logger.debug("User saved: #{user.id}")
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
    raise Aclog::Exceptions::UserNotRegistered unless registered?

    Rails.cache.fetch("stats/#{self.id}", expires_in: 3.hours) do
      favorited_counts, retweeted_counts = self.tweets.pluck(:favorites_count, :retweets_count).transpose

      ret = OpenStruct.new
      ret.updated_at = Time.now
      ret.since_join = (DateTime.now.utc - self.account.created_at.to_datetime).to_i
      ret.favorites_count = self.favorites.count
      ret.retweets_count = self.retweets.count
      ret.tweets_count = self.tweets.count
      ret.favorited_count = favorited_counts.sum
      ret.retweeted_count = retweeted_counts.sum
      ret.average_favorited_count = favorited_counts.inject(:+).to_f / ret.tweets_count
      ret.average_retweeted_count = retweeted_counts.inject(:+).to_f / ret.tweets_count

      _conv = -> i { g = 10 ** (Math.log10(i).to_i - 2); "#{i / g * g}+" }
      ret.retweeted_count_str = _conv.call(ret.retweeted_count)
      ret.favorited_count_str = _conv.call(ret.favorited_count)

      ret
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
