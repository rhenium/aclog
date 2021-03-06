require "ostruct"

class User < ActiveRecord::Base
  has_many :tweets
  has_many :favorites
  has_many :retweets
  has_one :account

  scope :suggest_screen_name, ->(str) {
    escaped = str.gsub(/(_|%)/) {|x| "\\" + x }
    where("screen_name LIKE ?", escaped + "%")
  }

  class << self
    def find(*args)
      hash = args.first
      return super(*args) unless hash.is_a?(Hash)

      key, value = hash.delete_if {|k, v| v.nil? }.first
      key && where(hash).order(updated_at: :desc).first || raise(ActiveRecord::RecordNotFound, "Couldn't find User with #{hash.map {|k, v| "#{k}=#{v}" }.join(", ")}")
    end

    def transform_from_json_into_hash(json)
      {
        id: json[:id],
        screen_name: json[:screen_name],
        name: json[:name],
        profile_image_url: json[:profile_image_url_https] || json[:profile_image_url],
        protected: json[:protected]
      }
    end

    def build_from_json(json)
      self.new(transform_from_json_into_hash(json))
    end

    def create_or_update_from_json(json)
      import([build_from_json(json)], on_duplicate_key_update: [:screen_name, :name, :profile_image_url, :protected])
    end

    def create_or_update_bulk_from_json(array)
      return if array.empty?

      objects = array.map {|json| transform_from_json_into_hash(json) }
      keys = objects.first.keys
      import(keys, objects.map(&:values),
             on_duplicate_key_update: [:screen_name, :name, :profile_image_url, :protected],
             validate: false)
    end
  end

  def id_str
    id.to_s
  end

  def protected?
    protected
  end

  def registered?
    !!account && account.active?
  end
  alias registered registered?

  def opted_out?
    !!account && account.opted_out?
  end

  def stats
    Rails.cache.fetch("users/#{self.id}/stats", expires_in: Settings.cache.stats) do
      plucked = self.tweets.select("COUNT(*) AS count, SUM(reactions_count) AS sum").reorder("").first.attributes

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

  def count_favorited_by
    Favorite
      .joins("INNER JOIN (#{self.tweets.reacted.order_by_id.limit(100).to_sql}) tweets ON tweets.id = favorites.tweet_id")
      .group("favorites.user_id")
      .count("favorites.user_id")
      .sort_by { |user_id, count| -count }.to_h
  end

  def count_favorited_users
    Tweet
      .joins("INNER JOIN (#{self.favorites.order(id: :desc).limit(300).to_sql}) m ON m.tweet_id = tweets.id")
      .group("tweets.user_id")
      .count("tweets.user_id")
      .sort_by { |user_id, count| -count }.to_h
  end

  def serializable_hash(options = nil)
    options ||= {}
    options[:methods] = Array(options[:methods])
    options[:methods] << :id_str
    options[:except] = Array(options[:except])
    options[:except] << :updated_at << :id
    super(options)
  end
end
