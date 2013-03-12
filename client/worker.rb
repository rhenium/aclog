require "time"
require "cgi"
require "em-twitter"
require "yajl"
require "./settings"
require "./logger"

class Worker
  class DBProxyClient < EM::Connection
    def initialize
      super
      @connections = []
      @receive_buf = ""
    end

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

    def format_source(source)
      source
    end

    def send_user(hash)
      out = {:id => hash[:id],
             :screen_name => hash[:screen_name],
             :name => hash[:name],
             :profile_image_url => hash[:profile_image_url_https]}
      send_data("USER #{Yajl::Encoder.encode(out)}\r\n")
    end

    def send_tweet(hash)
      send_user(hash[:user])
      out = {:id => hash[:id],
             :text => format_text_from_hash(hash),
             :source => format_source(hash[:source]),
             :tweeted_at => hash[:created_at],
             :user_id => hash[:user][:id]}
      send_data("TWEET #{Yajl::Encoder.encode(out)}\r\n")
    end

    def send_favorite(hash)
      send_tweet(hash[:target_object])
      send_user(hash[:source])
      out = {:tweet_id => hash[:target_object][:id],
             :user_id => hash[:source][:id]}
      send_data("FAVORITE #{Yajl::Encoder.encode(out)}\r\n")
    end

    def send_unfavorite(hash)
      send_tweet(hash[:target_object])
      send_user(hash[:source])
      out = {:tweet_id => hash[:target_object][:id],
             :user_id => hash[:source][:id]}
      send_data("UNFAVORITE #{Yajl::Encoder.encode(out)}\r\n")
    end

    def send_retweet(hash)
      send_tweet(hash[:retweeted_status])
      out = {:id => hash[:id],
             :tweet_id => hash[:id],
             :user_id => hash[:user][:id]}
      send_data("RETWEET #{Yajl::Encoder.encode(out)}\r\n")
    end

    def send_delete(hash)
      out = {:tweet_id => hash[:delete][:status][:id],
             :user_id => hash[:delete][:status][:user_id]}
      send_data("DELETE #{Yajl::Encoder.encode(out)}\r\n")
    end

    def post_init
      send_data("CONNECT #{Settings.secret_key}&#{Settings.worker_number}&#{Settings.worker_count}\r\n")
    end

    def unbind
      $logger.info("Connection closed")
      reconnect(@options[:host], @options[:port])
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
            p arg
            hash = ::Yajl::Parser.parse(arg.last, :symbolize_keys => true)
            con = EM::Twitter::Client.connect({
              :host => "userstream.twitter.com",
              :path => "/1.1/user.json",
              :oauth => {:consumer_key => Settings.consumer_key,
                         :consumer_secret => Settings.consumer_secret,
                         :token => hash[:oauth_token],
                         :token_secret => hash[:oauth_token_secret]},
              :method => "GET",
              # user data
              :user_id => hash[:user_id]
            })

            con.on_reconnect do |timeout, count|
              $logger.warn("Reconnected: #{con.options[:user_id]}/#{count}")
            end

            con.on_max_reconnects do |timeout, count|
              $logger.error("Reached Max Reconnects: #{con.options[:user_id]}")
            end

            con.on_unauthorized do
              $logger.error("Unauthorized: #{con.options[:user_id]}")
              @connections.delete(con)
              con.stop
            end

            con.on_forbidden do
              $logger.error("Forbidden: #{con.options[:user_id]}")
              @connections.delete(con)
            end

            con.on_not_found do
              $logger.error("Not Found: #{con.options[:user_id]}")
              @connections.delete(con)
            end

            con.on_not_acceptable do
              $logger.error("Not Acceptable: #{con.options[:user_id]}")
            end

            con.on_too_long do
              $logger.error("Too Long: #{con.options[:user_id]}")
            end

            con.on_range_unacceptable do
              $logger.error("Range Unacceptable: #{con.options[:user_id]}")
            end

            con.on_enhance_your_calm do
              $logger.error("Enhance Your Calm: #{con.options[:user_id]}")
              @connections.delete(con)
            end

            con.on_error do |message|
              $logger.error("Unknown: #{con.options[:user_id]}/#{message}")
            end

            con.each do |chunk|
              begin # convert error
                begin
                  status = ::Yajl::Parser.parse(chunk, :symbolize_keys => true)
                rescue ::Yajl::ParseError
                  $logger.warn("::Yajl::ParseError in stream: #{chunk}")
                  next
                end

                if status.is_a?(::Hash)
                  if status.key?(:user)
                    if status[:user][:id] == con.options[:user_id] &&
                       !status.key?(:retweeted_status)
                      send_tweet(status)
                      $logger.debug("Created Tweet")
                    elsif status.key?(:retweeted_status) &&
                          (status[:retweeted_status][:user][:id] == con.options[:user_id] ||
                           status[:user][:id] == con.options[:user_id])
                      send_retweet(status)
                      $logger.debug("Created Retweet")
                    end
                  elsif status[:event] == "favorite"
                    if status[:target_object][:user] &&
                      (!status[:target_object][:user][:protected] ||
                       status[:target_object][:user][:id] == con.options[:user_id])
                      send_favorite(status)
                      $logger.debug("Created Favorite")
                    end
                  elsif status[:event] == "unfavorite"
                    send_unfavorite(status)
                    $logger.debug("Destroyed Favorite")
                  elsif status.key?(:delete) && status[:delete].key?(:status)
                    send_delete(status)
                    $logger.debug("Destroyed Tweet: #{status[:delete][:status][:id]}/#{status[:delete][:status][:user_id]}")
                  else
                    # monyo
                  end
                else
                  $logger.warn("Unexpected object in stream: #{status}")
                  next
                end
              rescue # debug
                $logger.error($!)
                $logger.error($@)
              end
            end

            $logger.info("User connected: #{con.options[:user_id]}")
            @connections << con
          rescue ::Yajl::ParseError
            $logger.error("JSON Parse Error: #{json}")
          end
        end
      end
    end

    def stop_all
      @connections.map(&:stop)
      send_data("QUIT\r\n")
    end
  end

  def initialize
    $logger = Aclog::Logger.new(:debug)
  end

   def start
    $logger.info("Worker ##{Settings.worker_number} started")
    EM.run do
      stop = Proc.new do
        EM.stop
      end
      Signal.trap(:INT, &stop)
      Signal.trap(:TERM, &stop)

      EM.connect(Settings.db_proxy_host, Settings.db_proxy_port, DBProxyClient)
    end
  end
end


