require "em-twitter"
require "yajl"
require "./settings"

module Aclog
  module Collector
    class UserStream
      def initialize(logger, msg, &blk)
        @logger = logger
        @user_id = msg["user_id"]
        @account_id = msg["id"]
        @callback = blk
        prepare_client(msg)
      end

      def callback(event, data)
        @callback.call(event, data)
      end

      def prepare_client(msg)
        client = EM::Twitter::Client.new(make_opts(msg))
        client.on_error do |message|
          log(:error, "Unknown error: #{message}")
        end

        client.on_enhance_your_calm do
          log(:warn, "Enhance your calm")
        end

        client.on_no_data_received do
          log(:warn, "No data received")
        end

        client.on_close do
          log(:info, "disconnect")
        end

        client.on_reconnect do |timeout, retries|
          log(:info, "Reconnected: #{retries}")
        end

        client.on_max_reconnects do |timeout, retries|
          log(:warn, "Reached max reconnects: #{retries}")
          stop
        end

        client.on_unauthorized do
          log(:warn, "Unauthorized")
          callback(:unauthorized, id: @account_id)
          stop
        end

        client.on_service_unavailable do
          # account deleted?
          log(:warn, "Service unavailable")
          stop
        end

        client.each do |item|
          begin
            hash = Yajl::Parser.parse(item, symbolize_keys: true)
          rescue Yajl::ParseError
            log(:warn, "JSON parse error: #{item}")
            next
          end

          if hash[:warning]
            log(:warn, "warning: #{hash[:warning]}")
          elsif hash[:limit]
            log(:warn, "limit: #{hash[:limit][:track]}")
          elsif hash[:delete]
            if d = hash[:delete][:status]
              log(:debug, "delete: #{hash[:delete][:status]}")
              callback(:delete, d)
            end
          elsif hash[:event]
            case hash[:event]
            when "favorite"
              log(:debug, "favorite: #{hash[:source][:id]} => #{hash[:target_object][:id]}")
              callback(:favorite,
                       source: reduce_user(hash[:source]),
                       target_object: reduce_tweet(hash[:target_object]))
            when "unfavorite"
              log(:debug, "unfavorite: #{hash[:source][:id]} => #{hash[:target_object][:id]}")
              callback(:unfavorite,
                       source: reduce_user(hash[:source]),
                       target_object: reduce_tweet(hash[:target_object]))
            end
          elsif hash[:user]
            if hash[:retweeted_status]
              if hash[:retweeted_status][:user][:id] == @user_id || hash[:user][:id] == @user_id
                log(:debug, "retweet: #{hash[:user][:id]} => #{hash[:retweeted_status][:id]}")
                callback(:retweet,
                         id: hash[:id],
                         user: reduce_user(hash[:user]),
                         retweeted_status: reduce_tweet(hash[:retweeted_status]))
              end
            elsif hash[:user][:id] == @user_id
                log(:debug, "tweet: #{hash[:user][:id]} => #{hash[:id]}")
              callback(:tweet, reduce_tweet(hash))
            end
          elsif hash[:friends]
            log(:debug, "friends: #{hash[:friends].size}")
          elsif hash[:scrub_geo]
            log(:debug, "scrub_geo: #{hash}")
          else
            log(:info, "Unknown streaming data: #{hash}")
          end
        end
        @client = client
      end

      def start
        @client.connect
        log(:info, "Connected")
      end

      def update(hash)
        opts = make_opts(hash)
        if opts[:oauth][:token] != @client.options[:oauth][:token]
          log(:info, "update")
          @client.connection.update(opts)
        end
      end

      def stop
        @client.connection.stop
      end

      private
      def log(level, message)
        @logger.send(level, "[USERSTREAM:##{@account_id}:#{@user_id}] #{message}")
      end

      def make_opts(msg)
        { host: "userstream.twitter.com",
          path: "/1.1/user.json",
          params: { with: "user" },
          oauth: { consumer_key: msg["consumer_key"],
                   consumer_secret: msg["consumer_secret"],
                   token: msg["oauth_token"],
                   token_secret: msg["oauth_token_secret"] },
          method: :get }
      end

      def reduce_user(user)
        { id: user[:id],
          screen_name: user[:screen_name],
          name: user[:name],
          profile_image_url: user[:profile_image_url_https],
          protected: user[:protected] }
      end

      def reduce_tweet(status)
        { id: status[:id],
          text: status[:text],
          entities: status[:entities],
          source: status[:source],
          created_at: status[:created_at],
          in_reply_to_status_id: status[:in_reply_to_status_id],
          user: reduce_user(status[:user]) }
      end
    end
  end
end
