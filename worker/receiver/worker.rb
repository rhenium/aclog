require "time"

class Receiver::Worker
  def initialize
    @logger = Receiver::Logger.instance
  end

  # Create Aclog format text from Twitter Status Hash
  def format_text_from_hash(hash)
    text = hash[:text]
    entities = hash[:entities]

    return text unless entities

    gaps = {}
    replace = -> ents, bl do
      ents.each do |entity|
        starts = entity[:indices].first
        ends = entity[:indices].last
        rep = bl.call(entity)
        gaps[starts] = rep.size - (ends - starts)
        bgap = gaps.select{|k, v| k < starts}.values.inject(0){|s, m| s += m}
        text[starts + bgap...ends + bgap] = rep
      end
    end

    replace.call((entities[:media] || []) + (entities[:urls] || []),
                 -> entity {"<url:#{CGI.escapeHTML(entity[:expanded_url])}:#{CGI.escapeHTML(entity[:display_url])}>"})
    replace.call(entities[:hashtags] || [],
                 -> entity {"<hashtag:#{CGI.escapeHTML(URI.encode(entity[:text]))}>"})
    replace.call(entities[:user_mentions] || [],
                 -> entity {"<mention:#{CGI.escapeHTML(URI.encode(entity[:screen_name]))}>"})

    return text
  end

  # Create or Update user by Twitter User Hash
  def create_user_from_hash(user)
    rec = User.find_or_initialize_by(:id => user[:id])
    rec.screen_name = user[:screen_name]
    rec.name = user[:name]
    rec.profile_image_url = user[:profile_image_url_https]
    rec.save! if rec.changed?

    return rec
  end

  # Create tweet by Twitter Status Hash
  def create_tweet_from_hash(status)
    Tweet.find_by(:id => status[:id]) ||
    Tweet.create!(:id => status[:id],
                  :text => format_text_from_hash(status),
                  :source => status[:source],
                  :tweeted_at => Time.parse(status[:created_at]),
                  :user => create_user_from_hash(status[:user]))
  end

  def destroy_tweet_from_hash(status)
    Tweet.delete(status[:delete][:status][:id])
  end

  # Create Retweet by Twitter Status Hash
  def create_retweet_from_hash(status)
    Retweet.find_by(:id => status[:id]) ||
    Retweet.create!(:id => status[:id],
                    :tweet => create_tweet_from_hash(status[:retweeted_status]),
                    :user => create_user_from_hash(status[:user]))
  end

  # Create Favorite by Streaming Event Hash
  def create_favorite_from_hash(status)
    user = create_user_from_hash(status[:source])
    user.favorites.find_by(:tweet_id => status[:target_object][:id]) ||
    user.favorites.create!(:tweet => create_tweet_from_hash(status[:target_object]))
  end

  def destroy_favorite_from_hash(status)
    Favorite.delete_all("tweet_id = #{status[:target_object][:id]} AND " +
                        "user_id = #{status[:source][:id]}")
  end

  def start
    EM.run do
      # UserStreams connections
      @connections = []

      stop = Proc.new do
        @connections.map(&:stop)
        EM.stop
      end
      Signal.trap(:INT, &stop)
      Signal.trap(:TERM, &stop)

      register = -> account do
        con = EM::Twitter::Client.connect({
          :host => "userstream.twitter.com",
          :path => "/1.1/user.json",
          :oauth => {:consumer_key => Settings.consumer_key,
                     :consumer_secret => Settings.consumer_secret,
                     :token => account.oauth_token,
                     :token_secret => account.oauth_token_secret},
          :method => "GET",
          # user data
          :user_id => account.id
        })

        con.on_reconnect do |timeout, count|
          @logger.warn("Reconnected: #{con.options[:user_id]}/#{count}")
        end

        con.on_max_reconnects do |timeout, count|
          @logger.error("Reached Max Reconnects: #{con.options[:user_id]}")
        end

        con.on_unauthorized do
          @logger.error("Unauthorized: #{con.options[:user_id]}")
          @connections.delete(con)
        end

        con.on_forbidden do
          @logger.error("Forbidden: #{con.options[:user_id]}")
          @connections.delete(con)
        end

        con.on_not_found do
          @logger.error("Not Found: #{con.options[:user_id]}")
          @connections.delete(con)
        end

        con.on_not_acceptable do
          @logger.error("Not Acceptable: #{con.options[:user_id]}")
        end

        con.on_too_long do
          @logger.error("Too Long: #{con.options[:user_id]}")
        end

        con.on_range_unacceptable do
          @logger.error("Range Unacceptable: #{con.options[:user_id]}")
        end

        con.on_enhance_your_calm do
          @logger.error("Enhance Your Calm: #{con.options[:user_id]}")
        end

        con.on_error do |message|
          @logger.error("Unknown: #{con.options[:user_id]}/#{message}")
        end

        con.each do |json|
          begin # convert error
            begin
              status = ::Yajl::Parser.parse(json, :symbolize_keys => true)
            rescue ::Yajl::ParseError
              @logger.warn("::Yajl::ParseError in stream: #{json}")
              next
            end

            if status.is_a?(::Hash)
              if status.key?(:user)
                # Tweet or Retweet
                if status[:user][:id] == con.options[:user_id] &&
                   !status.key?(:retweeted_status)
                  # Tweet
                  create_tweet_from_hash(status)
                  @logger.debug("Created Tweet")
                elsif status.key?(:retweeted_status) &&
                      (status[:retweeted_status][:user][:id] == con.options[:user_id] ||
                       status[:user][:id] == con.options[:user_id])
                  # Retweet
                  create_retweet_from_hash(status)
                  @logger.debug("Created Retweet")
                end
              elsif status[:event] == "favorite"
                # Favorite
                create_favorite_from_hash(status)
                @logger.debug("Created Favorite")
              elsif status[:event] == "unfavorite"
                # Unfavorite
                destroy_favorite_from_hash(status)
                @logger.debug("Destroyed Favorite")
              elsif status.key?(:delete) && status[:delete].key?(:status)
                # Delete
                destroy_tweet_from_hash(status)
                @logger.debug("Destroyed Tweet")
              else
                # Else - do nothing
                # p status
              end
            else
              @logger.warn("Unexpected object in stream: #{status}")
              next
            end
          rescue # debug
            @logger.error($!)
            @logger.error($@)
          end
        end

        @logger.info("User connected: #{con.options[:user_id]}")
        @connections << con
      end

      # EventReceiver
      #EM.start_server("127.0.0.1", Settings.worker_port) do |server|
      #  def server.receive_data(data)
      #    d = data.split(/ /)

      #    if handle_event(d[0].to_sym, s[1].to_i)
      #      send_data "Accepted\r\n"
      #    else
      #      send_data "Denied\r\n"
      #    end

      #    close_connection_after_writing
      #  end

      #  def handle_event(command, id)
      #    case command
      #    when :REGISTER
      #      if account = Account.find_by(:id => id)
      #        register.call(account)
      #        return true
      #      else
      #        return false
      #      end
      #    end
      #  end
      #end

      reconnect = -> do
        Account.all.each do |account|
          if con = @connections.find{|m| m.options[:user_id] == account.id}
            con.immediate_reconnect
          else
            register.call(account)
          end
        end
      end

      EM.add_periodic_timer(30 * 60) do
        reconnect.call
      end

      reconnect.call
    end
  end
end


