require "msgpack"
require "./settings"
require "./user_stream"

module Aclog::Collector
  class Connection < EM::Connection
    def initialize(logger)
      @logger = logger
      @clients = {}
      @unpacker = MessagePack::Unpacker.new(symbolize_keys: true)
      @exiting = false
    end

    def post_init
      send_object(type: "auth",
                  secret_key: Settings.secret_key)
    end

    def unbind
      if !@exiting
        log(:info, "reconnecting...")

        EM.add_timer(10) do
          reconnect(Settings.receiver_host, Settings.receiver_port)
          post_init
        end
      end
    end

    def receive_data(data)
      @unpacker.feed_each(data) do |msg|
        unless msg.is_a?(Hash) && msg[:type]
          log(:warn, "unknown data: #{msg}")
          return
        end

        case msg[:type]
        when "ok"
          log(:info, "connection established")
        when "error"
          log(:error, "error: #{msg}")
        when "fatal"
          log(:fatal, "fatal: #{msg}")
        when "account"
          account_id = msg[:id]
          if @clients[account_id]
            @clients[account_id].update(msg)
            log(:info, "updated: #{account_id}")
          else
            stream = UserStream.new(@logger, msg, ->(event, data) { send_object(data.merge(type: event)) })
            stream.start
            @clients[account_id] = stream
            log(:info, "registered: #{account_id}")
          end
        when "stop"
          account_id = msg[:id]
          client = @clients[account_id]
          if client
            client.stop
            @clients.delete(account_id)
            log(:info, "unregistered: #{account_id}")
          end
        else
          log(:warn, "unknown message: #{msg}")
        end
      end
    end

    def quit
      @exiting = true
      send_object(type: "quit", reason: "stop")
      @clients.values.each(&:stop)
    end

    private
    def send_object(data)
      send_data(data.to_msgpack)
    end

    def log(level, message)
      @logger.__send__(level, "[WORKER] #{message}")
    end
  end
end


