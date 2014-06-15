require "ostruct"

class User < ActiveRecord::Base
  has_many :tweets
  has_many :favorites
  has_many :retweets
  has_one :account

  scope :suggest_screen_name, ->(str) { where("screen_name LIKE ?", "#{str.gsub(/(_|%)/) {|x| "\\" + x }}%").order(screen_name: :asc) }

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
                 profile_image_url: json[:profile_image_url_https] || json[:profile_image_url],
                 protected: json[:protected])
      end

      self.import(objects, on_duplicate_key_update: [:screen_name, :name, :profile_image_url, :protected])
    end
  end

  def twitter_url
    "https://twitter.com/#{self.screen_name}"
  end

  def profile_image_url(size = nil)
    if size == :original
      suffix = ""
    else
      suffix = "_#{size || :normal}"
    end

    attributes["profile_image_url"].sub(/_normal((?:\.(?:png|jpeg|gif))?)/, "#{suffix}\\1")
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

  def permitted_to_see?(user)
    !user.protected? || user.id == self.id || (self.registered? && account.following?(user))
  end

  def stats
    Rails.cache.fetch("users/#{self.id}/stats", expires_in: Settings.cache.stats) do
      plucked = self.tweets.select("COUNT(*) AS count, SUM(reactions_count) AS sum").first.attributes

      ret = OpenStruct.new
      ret.updated_at = Time.now
      ret.tweets_count = plucked["count"]
      ret.reactions_count = plucked["sum"]
      ret.registered = self.registered?

      if self.registered?
        ret.since_join = (DateTime.now.utc - self.account.created_at.to_datetime).to_i
      end
      
      ret
    end
  end

  def count_discovered_by
    [Favorite, Retweet].map { |klass|
      klass
        .joins("INNER JOIN (#{self.tweets.reacted.order_by_id.limit(100).to_sql}) tweets ON tweets.id = #{klass.table_name}.tweet_id")
        .group("`#{klass.table_name}`.`user_id`")
        .count("`#{klass.table_name}`.`user_id`")
    }.inject { |m, s|
      m.merge(s) { |key, first, second| first.to_i + second.to_i }
    }.sort_by { |user_id, count| -count }
  end

  def count_discovered_users
    [Favorite, Retweet].map { |klass|
      Tweet
        .joins("INNER JOIN (#{self.__send__(klass.table_name.to_sym).order(id: :desc).limit(500).to_sql}) m ON m.tweet_id = tweets.id")
        .group("tweets.user_id")
        .count("tweets.user_id")
    }.inject { |m, s|
      m.merge(s) { |key, first, second| first.to_i + second.to_i }
    }.sort_by { |user_id, count| -count }
  end
end
