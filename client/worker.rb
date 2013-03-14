require "time"
require "em-twitter"
require "twitter"
require "yajl"
require "./settings"
require "./logger"

module EM
  class Connection
    def send_chunk(data)
      puts data
      send_data(data + "\r\n")
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

      entities = status.attrs[:entities].values.flatten.sort_by{|entity| entity[:indices].first}

      result = []
      last_index = entities.inject(0) do |last_index, entity|
        result << chars[last_index...entity[:indices].first]
        result << if entity[:url]
                    "<url:#{CGI.escape(entity[:expanded_url])}:#{CGI.escape(entity[:display_url])}>"
                  elsif entity[:text]
                    "<hashtag:#{CGI.escape(entity[:text])}>"
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
      out = {:secret_key => Settings.secret_key,
             :worker_number => Settings.worker_number,
             :worker_count => Settings.worker_count}
      send_chunk("CONNECT #{Yajl::Encoder.encode(out)}")
    end

    def unbind
      $logger.info("Connection closed")
      EM.add_timer(10) do
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
          rescue Yajl::ParseError
            $logger.error("JSON Parse Error: #{json}")
            next
          end

          @clients << client = EM::Twitter::Client.connect({
            :host => "userstream.twitter.com",
            :path => "/1.1/user.json",
            :oauth => {
              :consumer_key => Settings.consumer_key,
              :consumer_secret => Settings.consumer_secret,
              :token => hash[:oauth_token],
              :token_secret => hash[:oauth_token_secret]},
            :method => "GET"})
          user_id = hash[:user_id]
          row_id = hash[:id]

          client.on_error do |message|
            $logger.warn("Unknown Error(##{user_id}): #{message}")
          end

          client.on_unauthorized do
            # revoked?
            $logger.warn("Unauthorized(##{user_id})")
            send_chunk("UNAUTHORIZED #{row_id}&#{user_id}")
            client.connection.stop
            @clients.delete(client)
          end

          client.on_enhance_your_calm do
            # limit?
            $logger.warn("Enhance your calm(##{user_id})")
          end

          client.on_no_data_received do
            # (?)
            $logger.warn("No data received(##{user_id})")
            client.close_connection
          end

          client.each do |chunk|
            begin
              hash = Yajl::Parser.parse(chunk, :symbolize_keys => true)
            rescue Yajl::ParseError
              $logger.warn("Unexpected chunk(##{user_id}): #{chunk}")
              next
            end

            if hash[:warning]
              $logger.info("Stall warning(##{user_id}): #{hash[:warning]}")
            elsif hash[:delete] && hash[:delete][:status]
              send_delete(hash[:delete][:status][:id], hash[:delete][:status][:user_id])
            elsif hash[:limit]
              $logger.warn("UserStreams Limit Event(##{user_id}): #{hash[:limit][:track]}")
            elsif hash[:event]
              case hash[:event]
              when "favorite"
                source = Twitter::User.new(hash[:source])
                target_object = Twitter::Tweet.new(hash[:target_object])
                unless target_object.user.protected && target_object.user.id != user_id
                  send_favorite(source, target_object)
                end
              when "unfavorite"
                send_unfavorite(Twitter::User.new(hash[:source]), Twitter::Tweet.new(hash[:target_object]))
              end
            elsif hash[:text] && hash[:user]
              # tweet
              status = Twitter::Tweet.new(hash)
              if status.retweeted_status && (status.retweeted_status.user.id == user_id ||
                                             status.user.id == user_id)
                $logger.debug("Retweet(##{user_id})")
                send_retweet(status)
              elsif status.user.id == user_id
                send_tweet(status)
              end
            end
          end

          client.on_reconnect do |timeout, retries|
            $logger.warn("Reconnected(##{user_id}): #{retries}")
          end

          client.on_max_reconnects do |timeout, retries|
            $logger.warn("Max reconnects: #{row_id}/#{user_id}")
            client.connection.stop
            @clients.delete(client)
          end

          $logger.info("Connected(##{user_id})")
        end
      end
    end

    def stop_all
      @clients.map{|c| c.connection.stop}
      send_chunk("QUIT")
    end
  end

  def initialize
    $logger = Aclog::Logger.new(:warn)
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


