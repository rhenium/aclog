require "eventmachine"
require "msgpack"

module WorkerNode
  class CollectorConnection < EM::Connection
    def initialize
      @streams = {}
      @unpacker = MessagePack::Unpacker.new(symbolize_keys: true)
      @exiting = false
    end

    def post_init
      log(:info, "Connection established, trying to authenticate...")
      send_message(:auth,
                   secret_key: Settings.secret_key)
    end

    def unbind
      unless @exiting
        log(:warn, "Connection was closed unexpectedly. Trying to reconnect...")

        EM.add_timer(10) do
          reconnect(Settings.collector_host, Settings.collector_port)
          post_init
        end
      end
    end

    def receive_data(data)
      @unpacker.feed_each(data) do |msg|
        unless msg.is_a?(Hash) && msg[:title]
          log(:warn, "Unknown data: #{msg}")
          next
        end

        parse_message(msg)
      end
    end

    def exit
      @exiting = true
      send_message(:exit, text: "Process is exiting.")
      stop_streams
    end

    private
    def parse_message(msg)
      case msg[:title]
      when "authenticated"
        log(:info, "Connection authenticated.")
      when "error"
        log(:error, "Error: #{msg}")
      when "fatal"
        log(:fatal, "Fatal: #{msg}")
      when "register"
        register_account(msg)
      when "unregister"
        unregister_account(msg)
      else
        log(:warn, "Unknown message: #{msg}")
      end
    end

    def register_account(msg)
      account_id = msg[:id]
      if @streams[account_id]
        @streams[account_id].update(msg)
        log(:info, "Updated account: #{account_id}")
      else
        stream = UserStream.new(msg, method(:send_message))
        stream.start
        @streams[account_id] = stream
        log(:info, "Registered account: #{account_id}")
      end
    end

    def unregister_account(msg)
      account_id = msg[:id]
      if @streams[account_id]
        @streams[account_id].stop
        @streams.delete(account_id)
        log(:info, "Unregistered account: #{account_id}")
      end
    end

    def stop_streams
      @streams.each do |id, stream|
        stream.stop
      end
    end

    def send_message(title, data)
      send_data(data.merge(title: title).to_msgpack)
    end

    def log(level, message)
      WorkerNode.logger.__send__(level, "[CollectorConnection] #{message}")
    end
  end
end


