require "ostruct"

class User < ActiveRecord::Base
  has_many :tweets, dependent: :delete_all
  has_many :favorites, dependent: :delete_all
  has_many :retweets, dependent: :delete_all
  has_one :account

  def twitter_url
    "https://twitter.com/#{self.screen_name}"
  end

  def following?(user)
    raise Aclog::Exceptions::UserNotRegistered unless registered?
    account.following?(user.id)
  end

  def private?
    !registered? || registered? && account.private?
  end

  def self.find(*args)
    hash = args.first
    return super(*args) unless hash.is_a?(Hash)

    key, value = hash.delete_if {|k, v| v.nil? }.first

    key && where(key => value).order(updated_at: :desc).first || raise(ActiveRecord::RecordNotFound, "Couldn't find User with #{key}=#{value}")
  end

  def self.from_json(json)
    user = where(id: json[:id]).first_or_initialize
    orig = user.attributes.dup

    user.screen_name = json[:screen_name]
    user.name = json[:name]
    user.profile_image_url = json[:profile_image_url]
    user.protected = json[:protected]

    if user.attributes == orig
      logger.debug("User was not updated: #{user.id}")
    else
      user.save!
      logger.debug("Successfully saved an user: #{user.id}")
    end

    user
  end

  def protected?
    protected
  end

  def registered?
    !!account
  end

  def permitted_to_see?(user)
    !user.protected? || user.id == self.id || self.account.try(:following?, user.id) || false
  end

  def profile_image_url_mini
    profile_image_url.sub(/_normal((?:\.(?:png|jpeg|gif))?)/, "_mini\\1")
  end

  def profile_image_url_original
    profile_image_url.sub(/_normal((?:\.(?:png|jpeg|gif))?)/, "\\1")
  end

  def stats
    raise Aclog::Exceptions::UserNotRegistered.new(self) unless registered? && account.active?

    Rails.cache.fetch("stats/#{self.id}", expires_in: 3.hours) do
      reactions_count = tweets.sum(:reactions_count)

      ret = OpenStruct.new
      ret.updated_at = Time.now
      ret.since_join = (DateTime.now.utc - self.account.created_at.to_datetime).to_i
      ret.favorites_count = self.favorites.count
      ret.retweets_count = self.retweets.count
      ret.tweets_count = self.tweets.count
      ret.reactions_count = reactions_count
      ret.average_reactions_count = reactions_count.to_f / ret.tweets_count

      ret
    end
  end

  def count_discovered_by
    tws = Tweet.arel_table
    f = -> model do
      klas = model.arel_table
      m = tws.project(tws[:id]).where(tws[:user_id].eq(self.id)).order(tws[:id].desc).take(100).as("m")
      query = klas.project(klas[:user_id], klas[:user_id].count).join(m).on(klas[:tweet_id].eq(m[:id])).group(klas[:user_id])
      ActiveRecord::Base.connection.exec_query(query.to_sql).rows
    end
    merge_count_user(f.call(Favorite), f.call(Retweet))
  end

  def count_discovered_users
    tws = Tweet.arel_table
    f = -> model do
      klas = model.arel_table
      m = klas.project(klas[:tweet_id]).where(klas[:user_id].eq(self.id)).order(klas[:id].desc).take(500).as("m")
      query = tws.project(tws[:user_id], tws[:user_id].count).join(m).on(tws[:id].eq(m[:tweet_id])).group(tws[:user_id])
      ActiveRecord::Base.connection.exec_query(query.to_sql).rows
    end
    merge_count_user(f.call(Favorite), f.call(Retweet))
  end

  private
  def merge_count_user(*args)
    ret = {}
    args.each_with_index do |o, i|
      o.each do |user_id, count|
        ret[user_id] ||= Array.new(args.size, 0)
        ret[user_id][i] = count
      end
    end
    ret.map(&:flatten).sort_by {|user_id, *counts| -counts.sum }
  end
end

