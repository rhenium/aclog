require "ostruct"

class User < ActiveRecord::Base
  has_many :tweets, dependent: :delete_all
  has_many :favorites, dependent: :delete_all
  has_many :retweets, dependent: :delete_all
  has_one :account

  class << self
    def find(*args)
      hash = args.first
      return super(*args) unless hash.is_a?(Hash)

      key, value = hash.delete_if {|k, v| v.nil? }.first

      key && where(key => value).order(updated_at: :desc).first || raise(ActiveRecord::RecordNotFound, "Couldn't find User with #{key}=#{value}")
    end

    def create_or_update_bulk_from_json(array)
      objects = array.map do |json|
        self.new(id: json[:id],
                 screen_name: json[:screen_name],
                 name: json[:name],
                 profile_image_url: json[:profile_image_url],
                 protected: json[:protected])
      end

      self.import(objects, on_duplicate_key_update: [:screen_name, :name, :profile_image_url, :protected])
    end
  end

  def twitter_url
    "https://twitter.com/#{self.screen_name}"
  end

  def profile_image_url_original
    profile_image_url.sub(/_normal((?:\.(?:png|jpeg|gif))?)/, "\\1")
  end

  def profile_image_url_reasonably_small
    profile_image_url.sub(/_normal((?:\.(?:png|jpeg|gif))?)/, "_reasonably_small\\1")
  end

  def profile_image_url_bigger
    profile_image_url.sub(/_normal((?:\.(?:png|jpeg|gif))?)/, "_bigger\\1")
  end

  def profile_image_url_mini
    profile_image_url.sub(/_normal((?:\.(?:png|jpeg|gif))?)/, "_mini\\1")
  end

  def protected?
    protected
  end

  def registered?
    !!account && account.active?
  end

  def private?
    !registered? || registered? && account.private?
  end

  def following?(user)
    raise Aclog::Exceptions::UserNotRegistered unless registered?
    account.following?(user.id)
  end

  def permitted_to_see?(user)
    !user.protected? || user.id == self.id || self.following?(user) || false
  end

  def stats
    Rails.cache.fetch("users/#{self.id}/stats", expires_in: Settings.cache.stats) do
      plucked = self.tweets.select("COUNT(*) AS count, SUM(reactions_count) AS sum").first.attributes

      ret = OpenStruct.new
      ret.updated_at = Time.now
      ret.since_join = (DateTime.now.utc - self.account.created_at.to_datetime).to_i
      ret.tweets_count = plucked["count"]
      ret.reactions_count = plucked["sum"]
      
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

