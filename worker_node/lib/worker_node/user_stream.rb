require "em-twitter"
require "yajl"

module WorkerNode
  class UserStream
    def initialize(msg, queue)
      @user_id = msg[:user_id]
      @account_id = msg[:id]
      @queue = queue
      prepare_client(msg)
    end

    def start
      @client.connect
      log(:info, "Connected")
    end

    def update(hash)
      opts = client_opts(hash)
      if opts[:oauth][:token] != @client.options[:oauth][:token]
        @client.connection.update(opts)
      end
    end

    def stop
      @client.connection.stop
    end

    private
    def prepare_client(msg)
      client = EM::Twitter::Client.new(client_opts(msg))

      client.on_error do |message|
        log(:error, "Unknown error: #{message}")
      end

      client.on_no_data_received do
        log(:warn, "No data received.")
      end

      client.on_reconnect do |timeout, retries|
        log(:info, "Reconnected: #{retries}")
      end

      client.on_max_reconnects do |timeout, retries|
        log(:warn, "Reached max reconnects: #{retries}")
        self.stop
      end

      client.on_unauthorized do
        log(:warn, "Unauthorized")
        @queue.push(:unauthorized, id: @account_id, user_id: @user_id)
        self.stop
      end

      client.on_service_unavailable do
        # Twitter account deleted?
        log(:warn, "Service unavailable.")
        self.stop
      end

      client.each do |item|
        begin
          json = Yajl::Parser.parse(item, symbolize_keys: true)
        rescue Yajl::ParseError
          log(:warn, "JSON parse error: #{item}")
          next
        end

        if json[:delete] && json[:delete][:status]
          on_delete(json)
        elsif json[:event] == "favorite"
          on_favorite(json)
        elsif json[:event] == "unfavorite"
          on_unfavorite(json)
        elsif json[:user] && json[:retweeted_status]
          on_retweet(json)
        elsif json[:user]
          on_tweet(json)
        elsif json[:friends]
          log(:debug, "friends: #{json[:friends].size}")
        elsif json[:warning]
          log(:warn, "warning: #{json[:warning]}")
        else
          # scrub_geo, limit, unknown message
        end
      end
      @client = client
    end

    def on_tweet(json)
      log(:debug, "Tweet: #{json[:user][:id]} => #{json[:id]}")
      @queue.push(:tweet,
                  reduce_tweet(json).merge(
                  unique_id: json[:id]))
    end

    def on_retweet(json)
      log(:debug, "Retweet: #{json[:user][:id]} => #{json[:retweeted_status][:id]}")
      @queue.push(:retweet,
                  id: json[:id],
                  user: reduce_user(json[:user]),
                  retweeted_status: reduce_tweet(json[:retweeted_status]),
                  unique_id: json[:id])
    end

    def on_favorite(json)
      log(:debug, "Favorite: #{json[:source][:id]} => #{json[:target_object][:id]}")
      @queue.push(:favorite,
                  source: reduce_user(json[:source]),
                  target_object: reduce_tweet(json[:target_object]),
                  unique_id: "fav-#{json[:created_at]}-#{json[:source][:id]}-#{json[:target_object][:id]}")
    end

    def on_unfavorite(json)
      log(:debug, "Unfavorite: #{json[:source][:id]} => #{json[:target_object][:id]}")
      @queue.push(:unfavorite,
                  source: reduce_user(json[:source]),
                  target_object: reduce_tweet(json[:target_object]),
                  unique_id: "unfav-#{json[:created_at]}-#{json[:source][:id]}-#{json[:target_object][:id]}")
    end

    def on_delete(json)
      log(:debug, "Delete: #{json[:delete][:status]}")
      @queue.push(:delete,
                  json.merge(
                  unique_id: "delete-#{json[:delete][:status][:id]}"))
    end

    def client_opts(msg)
      {
        method: :get,
        host: "userstream.twitter.com",
        path: "/1.1/user.json",
        params: { include_followings_activity: true },
        oauth: {
          consumer_key: msg[:consumer_key],
          consumer_secret: msg[:consumer_secret],
          token: msg[:oauth_token],
          token_secret: msg[:oauth_token_secret]
        }
      }
    end

    def reduce_user(user)
      {
        id: user[:id],
        screen_name: user[:screen_name],
        name: user[:name],
        profile_image_url_https: user[:profile_image_url_https],
        protected: user[:protected] 
      }
    end

    def reduce_tweet(status)
      {
        id: status[:id],
        text: status[:text],
        entities: status[:entities],
        source: status[:source],
        created_at: status[:created_at],
        in_reply_to_status_id: status[:in_reply_to_status_id],
        favorite_count: status[:favorite_count],
        retweet_count: status[:retweet_count],
        user: reduce_user(status[:user])
      }
    end

    def log(level, message)
      WorkerNode.logger.__send__(level, "[UserStream:##{@account_id}:#{@user_id}] #{message}")
    end
  end
end
