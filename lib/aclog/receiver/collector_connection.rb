module Aclog
  module Receiver
    class CollectorConnection < EM::Connection
      def initialize(channel, connections)
        @channel = channel
        @connections = connections

        @worker_number = nil
        @unpacker = MessagePack::Unpacker.new
      end

      def send_account(account)
        send_object(type: "account",
                    id: account.id,
                    consumer_key: Settings.consumer.key,
                    consumer_secret: Settings.consumer.secret,
                    oauth_token: account.oauth_token,
                    oauth_token_secret: account.oauth_token_secret,
                    user_id: account.user_id)
        log(:debug, "send: #{account.id}/#{account.user_id}")
      end

      def send_stop_account(account)
        send_object(type: "stop",
                    id: account.id)
        log(:debug, "send stop: #{account.id}/#{account.user_id}")
      end

      def post_init
      end

      def unbind
        @connections.reject! {|k, v| v == self }
        log(:info, "connection closed")
      end

      def receive_data(data)
        @unpacker.feed_each(data) do |msg|
          unless msg.is_a?(Hash) && msg["type"]
            log(:error, "unknown data: #{msg}")
            send_object(type: "fatal", message: "unknown data")
            close_connection_after_writing
            return
          end

          unless @authorized
            if msg["type"] == "auth"
              auth(msg)
            else
              log(:warn, "not authorized client: #{msg}")
              send_object(type: "fatal", message: "You aren't authorized")
              close_connection_after_writing
            end
            return
          end

          case msg["type"]
          when "unauthorized"
            @channel << -> {
              log(:warn, "unauthorized: ##{msg["id"]}/#{msg["user_id"]}")
            }
          when "tweet"
            @channel << -> {
              log(:debug, "receive tweet: #{msg["id"]}")
              Tweet.from_receiver(msg)
            }
          when "favorite"
            @channel << -> {
              log(:debug, "receive favorite: #{msg["source"]["id"]} => #{msg["target_object"]["id"]}")
              if f = Favorite.from_receiver(msg)
                f.tweet.notify_favorite
              end
            }
          when "unfavorite"
            @channel << -> {
              log(:debug, "receive unfavorite: #{msg["source"]["id"]} => #{msg["target_object"]["id"]}")
              Favorite.delete_from_receiver(msg)
            }
          when "retweet"
            @channel << -> {
              log(:debug, "receive retweet: #{msg["user"]["id"]} => #{msg["retweeted_status"]["id"]}")
              Retweet.from_receiver(msg)
            }
          when "delete"
            @channel << -> {
              log(:debug, "receive delete: #{msg["id"]}")
              Tweet.delete_from_receiver(msg)
            }
          when "quit"
            log(:info, "receive quit: #{msg["reason"]}")
            send_data(type: "quit", message: "Bye")
            close_connection_after_writing
          else
            log(:warn, "unknown message: #{msg["type"]}")
            send_object(type: "error", message: "Unknown message type")
          end
        end
      end

      private
      def log(level, message)
        text = "[RECEIVER"
        text << ":#{@worker_number}" if @worker_number
        text << "] #{message}"
        Rails.logger.__send__(level, text)
      end

      def send_object(data)
        send_data(data.to_msgpack)
      end

      def auth(msg)
        secret_key = msg["secret_key"]
        unless secret_key == Settings.collector.secret_key
          log(:warn, "Invalid secret_key: \"#{secret_key}\"")
          send_object(type: "fatal", message: "invalid secret_key")
          close_connection_after_writing
          return
        end

        worker_number = (Settings.collector.count.times.to_a - @connections.keys).sort.first
        if worker_number == nil
          log(:warn, "all connection alive")
          send_object(type: "error", message: "all connection alive")
          close_connection_after_writing
          return
        end

        @connections[worker_number] = self
        @worker_number = worker_number
        @authorized = true
        log(:info, "connect")
        send_object(type: "ok", message: "connected")

        Account.set_of_collector(@worker_number).each do |account|
          send_account(account)
        end
      end
    end
  end
end

