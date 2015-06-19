module Collector
  class CollectorProxyConnection < EM::Connection
    @@_instance = nil

    def self.instance
      @@_instance
    end

    attr_reader :connected, :last_stats

    def initialize(queue)
      @@_instance = self
      @unpacker = MessagePack::Unpacker.new(symbolize_keys: true)
      @queue = queue
      @closing = false
      @connected = false
      @last_stats = nil
    end

    def post_init
      send_message(event: :auth,
                   data: { secret_key: Settings.collector.secret_key })
    end

    def unbind
      if @closing
        log(:info, "Connection was closed.")
        @connected = false
      else
        if @connected
          log(:info, "Connection was closed unexpectedly.")
          @connected = false
        end

        EM.add_timer(10) { try_reconnect }
      end
    end

    def try_reconnect
      reconnect(Settings.collector.proxy_host, Settings.collector.proxy_port)
      post_init
    end

    def receive_data(data)
      @unpacker.feed_each(data) do |msg|
        unless msg.is_a?(Hash) && msg[:event]
          log(:warn, "Unknown message: #{msg}")
          next
        end

        begin
          parse_message(msg)
        rescue
          log(:error, "Failed to parse message: #{msg}")
        end
      end
    rescue
      log(:fatal, "Failed to parse data: #{data}")
    end

    def exit
      send_message(event: :exit, data: nil)
      close_connection_after_writing
    end

    def register_account(account)
      data = { id: account.id,
               consumer_key: Settings.consumer.key,
               consumer_secret: Settings.consumer.secret,
               oauth_token: account.oauth_token,
               oauth_token_secret: account.oauth_token_secret,
               user_id: account.user_id }
      send_message(event: :register, data: data)
    end

    def unregister_account(account)
      data = { id: account.id,
               user_id: account.user_id }
      send_message(event: :unregister, data: data)
    end

    private
    def parse_message(msg)
      case msg[:event]
      when "unauthorized"
        log(:info, "Received unauthorized: ##{msg[:data][:id]}/#{msg[:data][:user_id]}")
        @queue.push_unauthorized(msg)
      when "user"
        log(:debug, "Received user: #{msg[:identifier]}")
        @queue.push_user(msg)
      when "tweet"
        log(:debug, "Received tweet: #{msg[:identifier]}")
        @queue.push_tweet(msg)
      when "favorite"
        log(:debug, "Receive favorite: #{msg[:identifier]}")
        @queue.push_favorite(msg)
      when "unfavorite"
        log(:debug, "Receive unfavorite: #{msg[:identifier]}")
        @queue.push_unfavorite(msg)
      when "retweet"
        log(:debug, "Receive retweet: #{msg[:identifier]}")
        @queue.push_retweet(msg)
      when "delete"
        log(:debug, "Receive delete: #{msg[:identifier]}")
        @queue.push_delete(msg)
      when "auth"
        log(:info, "Connection authenticated.")
        @connected = true
        register_accounts
      when "heartbeat"
        log(:debug, "Heartbeat: #{msg[:data][:id]}")
        send_message(event: :heartbeat, data: { id: msg[:data][:id] })
        @last_stats = msg[:data][:stats]
      else
        log(:warn, "Unknown message: #{msg.inspect}")
      end
    end

    def register_accounts
      Account.active.each do |account|
        register_account(account)
      end
    end

    def send_message(data)
      send_data(data.to_msgpack)
    end

    def log(level, message)
      Rails.logger.__send__(level, "CollectorProxyConnection") { message }
    end
  end
end
