require "time"
require "tweetstream"
require "yajl"
require "./settings"
require "./logger"

module EM
  class Connection
    def send_chunk(data)
      send_data(data + "\r\n")
    end
  end
end

module TweetStream
  class Client
    attr_reader :user_id, :row_id

    def _set_aclog(user_id, row_id)
      @user_id = user_id
      @row_id = row_id
    end
  end
end

class Worker
  class DBProxyClient < EM::Connection
    def initialize
      @clients = []
      @receive_buf = ""
    end

    def format_text(status)
      chars = status.text.to_s.split(//)

      entities = status.attrs[:entities].values.flatten.map do |entity|
        entity[:hashtag] = entity[:text] if entity[:text]
        entity
      end.sort_by{|entity| entity[:indices].first}

      result = []
      last_index = entities.inject(0) do |last_index, entity|
        result << chars[last_index...entity[:indices].first]
        result << if entity[:url]
                    "<url:#{CGI.escape(entity[:expanded_url])}:#{CGI.escape(entity[:display_url])}>"
                  elsif entity[:hashtag]
                    "<hashtag:#{CGI.escape(entity[:hashtag])}>"
                  elsif entity[:screen_name]
                    "<mention:#{CGI.escape(entity[:screen_name])}>"
                  elsif entity[:cashtag]
                    "<cashtag:#{CGI.escape(entity[:cashtag])}>"
                  end
        entity[:indices].last
      end
      result << chars[last_index..-1]

      result.flatten.join
    end

    def format_source(status)
      if status.source.index("<a")
        url = status.source.scan(/href="(.+?)"/).flatten.first
        name = status.source.scan(/>(.+?)</).flatten.first
        "<url:#{CGI.escape(url)}:#{CGI.escape(name)}>"
      else
        status.source
      end
    end

    def send_user(user)
      out = {:id => user.id,
             :screen_name => user.screen_name,
             :name => user.name,
             :profile_image_url => user.profile_image_url_https}
      send_chunk("USER #{Yajl::Encoder.encode(out)}")
    end

    def send_tweet(status)
      send_user(status.user)
      out = {:id => status.id,
             :text => format_text(status),
             :source => format_source(status),
             :tweeted_at => status.created_at,
             :user_id => status.user.id}
      send_chunk("TWEET #{Yajl::Encoder.encode(out)}")
      $logger.debug("Sent Tweet: #{status.id}")
    end

    def send_favorite(source, target_object)
      send_tweet(target_object)
      send_user(source)
      out = {:tweet_id => target_object.id,
             :user_id => source.id}
      send_chunk("FAVORITE #{Yajl::Encoder.encode(out)}")
      $logger.debug("Sent Favorite: #{source.id} => #{target_object.id}")
    end

    def send_unfavorite(source, target_object)
      out = {:tweet_id => target_object.id,
             :user_id => source.id}
      send_chunk("UNFAVORITE #{Yajl::Encoder.encode(out)}")
      $logger.debug("Sent Unfavorite: #{source.id} => #{target_object.id}")
    end

    def send_retweet(status)
      send_tweet(status.retweeted_status)
      send_user(status.user)
      out = {:id => status.id,
             :tweet_id => status.retweeted_status.id,
             :user_id => status.user.id}
      send_chunk("RETWEET #{Yajl::Encoder.encode(out)}")
      $logger.debug("Sent Retweet: #{status.user.id} => #{status.retweeted_status.id}")
    end

    def send_delete(status_id, user_id)
      out = {:tweet_id => status_id,
             :user_id => user_id}
      send_chunk("DELETE #{Yajl::Encoder.encode(out)}")
      $logger.debug("Sent Delete: #{user_id} => #{status_id}")
    end

    def post_init
      send_chunk("CONNECT #{Settings.secret_key}&#{Settings.worker_number}&#{Settings.worker_count}")
    end

    def unbind
      $logger.info("Connection closed")
      EM.add_timer(5) do
        reconnect(Settings.db_proxy_host, Settings.db_proxy_port)
        post_init
      end
    end

    def receive_data(data)
      @receive_buf << data
      while line = @receive_buf.slice!(/.+?\r\n/)
        line.chomp!
        next if line == ""
        arg = line.split(/ /, 2)
        case arg.first
        when "OK"
          $logger.info("Connected to DB Proxy")
        when "ERROR"
          $logger.error("Error: #{arg.last}")
        when "ACCOUNT"
          begin
            hash = ::Yajl::Parser.parse(arg.last, :symbolize_keys => true)

            @clients << client = TweetStream::Client.new(
              :consumer_key => Settings.consumer_key,
              :consumer_secret => Settings.consumer_secret,
              :oauth_token => hash[:oauth_token],
              :oauth_token_secret => hash[:oauth_token_secret],
              :auth_method => :oauth)
            client._set_aclog(hash[:user_id], hash[:id])

            client.on_error do |message|
              $logger.warn("UserStreams Error(##{client.user_id}): #{message}")
            end

            client.on_limit do |discarded_count|
              $logger.warn("UserStreams Limit Event(##{client.user_id}): #{discarded_count}")
            end

            client.on_unauthorized do
              # revoked?
              $logger.warn("Unauthorized(##{client.user_id})")
              send_chunk("UNAUTHORIZED #{client.row_id}&#{client.user_id}")
              client.stop_stream
              @clients.delete(client)
            end

            client.on_enhance_your_calm do
              # limit?
              $logger.warn("Enhance your calm(##{client.user_id})")
            end

            client.on_no_data_received do
              # (?)
              $logger.warn("No data received(##{client.user_id})")
              client.close_connection
            end

            client.on_reconnect do |timeout, retries|
              $logger.warn("Reconnected(##{client.user_id}): #{retries}")
            end

            client.on_stall_warning do |warning|
              $logger.info("Stall warning(##{client.user_id}): #{warning}")
            end

            client.on_timeline_status do |status|
              # tweets. includes retweets
              if status.retweeted_status && (status.retweeted_status.user.id == client.user_id ||
                                             status.user.id == client.user_id)
                send_retweet(status)
              elsif status.user.id == client.user_id
                send_tweet(status)
              end
            end

            client.on_event(:favorite) do |event|
              source = Twitter::User.new(event[:source])
              target_object = Twitter::Tweet.new(event[:target_object])
              unless target_object.user.protected && target_object.user.id != client.user_id
                send_favorite(source, target_object)
              end
            end

            client.on_event(:unfavorite) do |event|
              send_unfavorite(Twitter::User.new(event[:source]), Twitter::Tweet.new(event[:target_object]))
            end

            client.on_delete do |status_id, user_id|
              send_delete(status_id, user_id)
            end

            client.userstream
            $logger.info("Connected(##{client.user_id})")
          rescue ::Yajl::ParseError
            $logger.error("JSON Parse Error: #{json}")
          rescue TweetStream::ReconnectError
            $logger.warn("TweetStream::ReconnectError: #{client.row_id}/#{client.user_id}")
            client.stop_stream
            @clients.delete(client)
          end
        end
      end
    end

    def stop_all
      @clients.map(&:stop_stream)
      send_chunk("QUIT")
    end
  end

  def initialize
    $logger = Aclog::Logger.new(:debug)
  end

   def start
    $logger.info("Worker ##{Settings.worker_number} started")
    EM.run do
      connection = EM.connect(Settings.db_proxy_host, Settings.db_proxy_port, DBProxyClient)

      stop = Proc.new do
        connection.stop_all
        EM.stop
      end
      Signal.trap(:INT, &stop)
      Signal.trap(:TERM, &stop)
    end
  end
end


