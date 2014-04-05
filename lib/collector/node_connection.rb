module Collector
  class NodeConnection < EM::Connection
    attr_reader :connection_id

    @@_id = 0

    def initialize
      @unpacker = MessagePack::Unpacker.new(symbolize_keys: true)
      @connection_id = (@@_id += 1)
      @authenticated = false
      @closing = false
    end

    def unbind
      if @closing
        log(:info, "Connection was closed.")
      else
        log(:warn, "Connection was closed unexpectedly.")
        NodeManager.unregister(self)
      end
    end

    def receive_data(data)
      @unpacker.feed_each(data) do |msg|
        unless msg.is_a?(Hash) && msg[:title]
          log(:warn, "Unknown message: #{msg}")
          send_message(:error, text: "Unknown message.")
          close_connection_after_writing
          next
        end

        parse_message(msg)
      end
    end

    def register_account(account)
      send_message(:register,
                   id: account.id,
                   consumer_key: Settings.consumer.key,
                   consumer_secret: Settings.consumer.secret,
                   oauth_token: account.oauth_token,
                   oauth_token_secret: account.oauth_token_secret,
                   user_id: account.user_id)
      log(:info, "Registered account ##{account.id}/#{account.user_id}")
    end

    def unregister_account(account)
      send_message(:unregister,
                   id: account.id,
                   user_id: account.user_id)
      log(:info, "Unregistered account ##{account.id}/#{account.user_id}")
    end

    private
    def parse_message(msg)
      unless @authenticated
        if msg[:title] == "auth"
          authenticate_node(msg)
        else
          log(:error, "Unauthenticated client: #{msg}")
          send_message(:fatal, text: "You aren't authenticate.")
          close_connection_after_writing
        end
        return
      end

      case msg[:title]
      when "unauthorized"
        log(:info, "Received unauthorized: ##{msg[:id]}/#{msg[:user_id]}")
      when "tweet"
        log(:debug, "Received tweet: #{msg[:id]}")
        Tweet.create_from_json(msg)
      when "favorite"
        log(:debug, "Receive favorite: #{msg[:source][:id]} => #{msg[:target_object][:id]}")
        Tweet.transaction do
          f = Favorite.create_from_json(msg)
          Notification.notify_favorites_count(f.tweet)
        end
      when "unfavorite"
        log(:debug, "Receive unfavorite: #{msg[:source][:id]} => #{msg[:target_object][:id]}")
        Favorite.destroy_from_json(msg)
      when "retweet"
        log(:debug, "Receive retweet: #{msg[:user][:id]} => #{msg[:retweeted_status][:id]}")
        Retweet.create_from_json(msg)
      when "delete"
        log(:debug, "Receive delete: #{msg[:delete][:status][:id]}")
        Tweet.destroy_from_json(msg) || Retweet.destroy_from_json(msg)
      when "exit"
        log(:info, "Closing this connection...")
        @closing = true
        NodeManager.unregister(self)
      else
        log(:warn, "Unknown message: #{msg[:title]}")
        send_message(:error, text: "Unknown message.")
      end
    end

    def authenticate_node(msg)
      if msg.key?(:secret_key) && Settings.collector.secret_key == msg[:secret_key]
        @authenticated = true
        log(:info, "Connection authenticated.")
        send_message(:authenticated)
        NodeManager.register(self)
      else
        log(:warn, "Invalid secret_key: #{secret_key.inspect}")
        send_message(:fatal, text: "Invalid secret_key.")
        close_connection_after_writing
        return
      end
    end

    def send_message(title, hash = {})
      send_data(hash.merge(title: title).to_msgpack)
    end

    def log(level, message)
      Rails.logger.__send__(level, "[Node:#{@connection_id}] #{message}")
    end
  end
end
