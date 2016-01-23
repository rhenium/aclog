class Tweet < ActiveRecord::Base
  belongs_to :user

  belongs_to :in_reply_to, class_name: "Tweet"
  has_many :replies, class_name: "Tweet", foreign_key: "in_reply_to_id"

  has_many :favorites, -> { order("favorites.id") }, dependent: :delete_all
  has_many :retweets, -> { order("retweets.id") }, dependent: :delete_all

  has_many :favoriters, ->  { order("favorites.id") }, through: :favorites, source: :user
  has_many :retweeters, -> { order("retweets.id") }, through: :retweets, source: :user

  scope :recent, ->(period = 3.days) { where("tweets.id > ?", snowflake_min(Time.zone.now - period)) }
  scope :reacted, ->(count = nil) { where("reactions_count >= ?", (count || 1).to_i) }
  scope :not_protected, -> { joins(:user).references(:user).where(users: { protected: false }) }
  scope :registered, -> { joins(user: :account).references(:account).merge(Account.active) }

  scope :max_id, ->(id) { where("tweets.id <= ?", id.to_i) if id }
  scope :since_id, ->(id) { where("tweets.id > ?", id.to_i) if id }
  scope :not_reacted_than, ->(last_count, last_id) { where("reactions_count < ? OR (reactions_count = ? AND id < ?)", last_count, last_count, last_id) if last_count }
  scope :page, ->(page, page_per) { limit(page_per).offset((page - 1) * page_per) }

  scope :order_by_id, -> { order(id: :desc) }
  scope :order_by_reactions, -> { order(reactions_count: :desc, id: :desc) }

  scope :favorited_by, ->(user) { joins(:favorites).where(favorites: { user: user }) }

  class << self
    # Builds a new instance of Tweet and initialize with JSON data from Twitter API.
    # @note This method just builds an instance, doesn't save it.
    # @param [Hash] json Data from Twitter API
    # @return [Tweet] The new instance.
    def build_from_json(json)
      self.new(transform_from_json_into_hash(json))
    end

    def transform_from_json_into_hash(json)
      {
        id: json[:id],
        text: extract_entities(json),
        source: json[:source],
        tweeted_at: Time.parse(json[:created_at]),
        user_id: json[:user][:id],
        in_reply_to_id: json[:in_reply_to_status_id],
        favorites_count: json[:favorite_count].to_i,
        retweets_count: json[:retweet_count].to_i,
        reactions_count: json[:favorite_count].to_i + json[:retweet_count].to_i
      }
    end

    # Builds instances of Tweet and save them. This method is supposed to be used from collector daemon.
    # @param [Array<Hash>] array Data from collector.
    def create_bulk_from_json(array)
      return if array.empty?

      objects = array.map {|json| transform_from_json_into_hash(json) }
      keys = objects.first.keys
      self.import(keys, objects.map(&:values),
                  on_duplicate_key_update: [:favorites_count, :retweets_count, :reactions_count],
                  validate: false)
    end

    # Destroys Tweets from database. This method is supposed to be used from collector daemon.
    # @param [Array<Hash>] array An array of Streaming API delete events.
    def destroy_bulk_from_json(array)
      ids = array.map {|json| json[:delete][:status][:id] }
      self.where(id: ids).delete_all
      Favorite.where(tweet_id: ids).delete_all
      Retweet.where(tweet_id: ids).delete_all
    end

    # Update a Tweet from Twitter REST API.
    # If the current_user is not specified, An random account will be selected from database.
    # @param [Integer] id Target status ID.
    # @param [User] current_user The user to use its token.
    # @return [Tweet] The Tweet instance imported.
    def update_from_twitter(ids, current_user = nil)
      client = (current_user ? current_user.account : Account.random).client

      ids = [ids] unless Array === ids
      ids = ids.map { |id| id.to_i }.select { |id| id > 0 }
      raise Aclog::Exceptions::TweetNotFound, "specify at least one valid status ID" if ids.empty?

      currents = Tweet.where(id: ids).eager_load(:user).to_a # query immediately
      currenth = currents.map { |t| [t.id, t] }.to_h

      begin
        sts = client.statuses(ids).map { |st| st.retweet? ? st.retweeted_status : st }
      rescue Twitter::Error::NotFound, Twitter::Error::Forbidden
        sts = []
      end

      User.create_or_update_bulk_from_json(sts.map { |st| st.attrs[:user] })

      newjsons = sts.reject { |st| currenth[st.id] }.map { |st| st.attrs }
      Tweet.create_bulk_from_json(newjsons)

      exsts = sts.select { |st| currenth[st.id] }
      Tweet.where(id: exsts.map(&:id)).zip(exsts) do |tweet, st|
        tweet.update(text: extract_entities(st.attrs),
                     source: st.attrs[:source],
                     in_reply_to_id: (tweet.in_reply_to_id || st.attrs[:in_reply_to_status_id]),
                     favorites_count: st.attrs[:favorite_count].to_i,
                     retweets_count: st.attrs[:retweet_count].to_i,
                     reactions_count: st.attrs[:favorite_count].to_i + st.attrs[:retweet_count].to_i)
      end

      stsids = Set.new(sts.map(&:id))
      check_deleted(currents.reject { |t| stsids.include?(t.id) }, current_user)
    end

    def check_deleted(tweets, current_user = nil)
      client = (current_user ? current_user.account : Account.random).client

      user_cache = {}

      tweets.each { |tweet|
        begin
          client.status(tweet.id)
        rescue Twitter::Error::Forbidden
          tweet.user.update(protected: true)
        rescue Twitter::Error::NotFound
          u = user_cache[tweet.user.id] ||= (client.user(tweet.user.id) rescue :not_found)
          if u == :not_found
            tweet.user.update(protected: true)
          else
            tweet.destroy
          end
        end
      }
    end

    # Parses /\d+[dwmy]/ style query and returns recent tweets (Relation) in specified period.
    # @note When nil or unparsable string are specified, this method does nothing.
    # @param [String] param
    # @return [ActiveRecord::Relation]
    def parse_recent(param)
      match = param.to_s.match(/^(\d+)([a-z])$/)
      if match
        n = match[1].to_i
        case match[2]
        when "d" then recent(n.days)
        when "w" then recent(n.weeks)
        when "m" then recent(n.months)
        when "y" then recent(n.years)
        end
      else
        all
      end
    end

    # Filters tweets with original query string.
    # @param [String] query
    # @return [ActiveRecord::Relation]
    def filter_by_query(query)
      strings = []
      query = query.gsub(/"((?:\\"|[^"])*?)"/) {|m| strings << $1; "##{strings.size - 1}" }

      escape_text = -> str do
        str.gsub(/#(\d+)/) { strings[$1.to_i] }
           .gsub(/(_|%)/) {|x| "\\" + x }
           .gsub("*", "%")
           .gsub("?", "_")
      end

      parse_condition = ->(scoped, token) do
        positive = !token.slice!(/^[-!]/)

        where_args = case token
        when /^(?:user|from):([A-Za-z0-9_]{1,20})$/
          u = User.find_by(screen_name: $1)
          uid = u && u.id || -1
          { user_id: uid }
        when /^fav(?:orite)?s?:(\d+)$/
          ["favorites_count >= ?", $1.to_i]
        when /^(?:retweet|rt)s?:(\d+)$/
          ["retweets_count >= ?", $1.to_i]
        when /^(?:sum|(?:re)?act(?:ion)?s?):(\d+)$/
          ["reactions_count >= ?", $1.to_i]
        when /^(?:source|via):(.+)$/
          ["source LIKE ?", escape_text.call($1)]
        when /^text:(.+)$/
          ["text LIKE ?", "%" + escape_text.call($1) + "%"]
        else
          nil
        end

        positive ? scoped.where(where_args) : scoped.where.not(where_args)
      end

      query.scan(/\S+/).inject(self.all) {|s, token| parse_condition.call(s, token) }
    end

    private
    # replace t.co with expanded_url
    def extract_entities(json)
      entity_values = ((json.dig(:extended_entities, :media) || []) + (json.dig(:entities, :urls) || [])).select { |e| e && e[:url] }.sort_by.with_index {|e, i| [e[:indices].first, i] }
      text = json[:text]

      result = +""
      last_index = entity_values.inject(0) do |last_index, entity|
        is = entity[:indices]
        url = case entity[:type]
              when "photo"
                entity[:media_url_https]
              when "animated_gif", "video"
                entity.dig(:video_info, :variants)&.select { |var| var&.[](:content_type) == "video/mp4" }&.max_by { |var| var[:bitrate] }&.[](:url)
              else # plain url or unknown
                entity[:expanded_url]
              end
        if is.first >= last_index
          result << text[last_index...is.first]
          result << url
          is.last
        else
          result << " " << url
          last_index
        end
      end

      result << text[last_index..-1]
    rescue => e
      Rails.logger.error(e)
      json[:text]
    end

    def snowflake_min(time)
      (time.to_datetime.to_i * 1000 - 1288834974657) << 22
    end
  end

  def id_str
    id.to_s
  end

  # Searches the ancestors of this Tweet recursively up to specified level.
  # @param [Integer] max_level
  # @return [Array<Tweet>] The search result.
  def reply_ancestors(max_level = Float::INFINITY)
    nodes = []
    node = self
    level = 0

    while level < max_level && node.in_reply_to
      nodes << (node = node.in_reply_to)
      level += 1
    end
    nodes.reverse
  end

  # Searches the descendants of this Tweet recursively up to specified level.
  # @param [Integer] max_level
  # @return [Array<Tweet>] The search result.
  def reply_descendants(max_level = Float::INFINITY)
    nodes = []
    c_nodes = [self]
    level = 0

    while level < max_level && c_nodes.size > 0
      nodes.concat(c_nodes.map! {|node| node.replies }.flatten!)
      level += 1
    end
    nodes.sort_by(&:id)
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
