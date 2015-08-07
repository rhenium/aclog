require "set"

module Collector
  class NodeConnection < EM::Connection
    attr_reader :connection_id, :activated_at

    @@_id = 0

    def initialize(queue)
      @unpacker = MessagePack::Unpacker.new(symbolize_keys: true)
      @connection_id = @@_id; @@_id += 1
      @authenticated = false
      @closing = false
      @activated_at = nil
      @queue = queue
      @heartbeats = Set.new
    end

    def unbind
      @heartbeat_timer.cancel if @heartbeat_timer
      if @closing
        log(:info, "Connection was closed.")
      else
        log(:warn, "Connection was closed unexpectedly.")
        NodeManager.unregister(self)
      end
    end

    def receive_data(data)
      @unpacker.feed_each(data) do |msg|
        unless msg.is_a?(Hash) && msg[:event]
          log(:warn, "Unknown message: #{msg}")
          send_message(:error, text: "Unknown message.")
          close_connection_after_writing
          next
        end

        parse_message(msg)
      end
    end

    def register_account(account)
      send_message(event: :register,
                   data: { id: account.id,
                           consumer_key: Settings.consumer.key,
                           consumer_secret: Settings.consumer.secret,
                           oauth_token: account.oauth_token,
                           oauth_token_secret: account.oauth_token_secret,
                           user_id: account.user_id })
      log(:info, "Registered account ##{account.id}/#{account.user_id}")
    end

    def unregister_account(account)
      send_message(event: :unregister,
                   data: { id: account.id,
                           user_id: account.user_id })
      log(:info, "Unregistered account ##{account.id}/#{account.user_id}")
    end

    def activate(block_number)
      @activated_at = Time.now
      send_message(event: :activate,
                   data: { users: [] })
      Account.active.where("id % ? = ?", Settings.collector.nodes_count, block_number).each do |a|
        register_account(a)
      end
    end

    private
    def parse_message(msg)
      unless @authenticated
        if msg[:event] == "auth"
          authenticate_node(msg[:data])
        else
          log(:error, "Unauthenticated client: #{msg}")
          send_message(event: :error, data: "You aren't authenticated.")
          close_connection_after_writing
        end
        return
      end

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
      when "exit"
        log(:info, "Closing this connection...")
        @closing = true
        NodeManager.unregister(self)
      when "heartbeat"
        log(:debug, "Heartbeat reply: #{msg[:data]}")
        @heartbeats.delete(msg[:data])
      else
        log(:warn, "Unknown message: #{msg.inspect}")
        send_message(event: :error, data: "Unknown message.")
      end
    end

    def authenticate_node(data)
      if data.key?(:secret_key) && Settings.collector.secret_key == data[:secret_key]
        @authenticated = true
        log(:info, "Connection authenticated.")
        send_message(event: :auth, data: nil)
        NodeManager.register(self)
        @heartbeat_timer = EM.add_periodic_timer(10, &method(:heartbeat))
      else
        log(:warn, "Invalid secret_key: #{secret_key.inspect}")
        send_message(event: :error, data: "Invalid secret_key.")
        close_connection_after_writing
        return
      end
    end

    def send_message(data)
      send_data(data.to_msgpack)
    end

    def heartbeat
      if @heartbeats.size > 2 # 30 sec
        log(:warn, "Node is dead.")
        NodeManager.unregister(self)
        @heartbeat_timer.cancel
        @heartbeat_timer = nil
        @closing = true
        close_connection_after_writing
        return
      end

      id = Time.now.to_i
      @heartbeats << id
      send_message(event: :heartbeat, data: id)
    end

    def log(level, message)
      Rails.logger.__send__(level, "Node(#{@connection_id})") { message }
    end
  end
end
