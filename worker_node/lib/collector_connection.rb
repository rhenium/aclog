class CollectorConnection < EM::Connection
  def initialize
    @streams = {}
    @unpacker = MessagePack::Unpacker.new(symbolize_keys: true)
    @exiting = false

    EventChannel.subscribe &method(:send_message)
  end

  def connection_completed
    log(:info, "Connection established, trying to authenticate...")
    send_message(event: :auth,
                 data: { secret_key: Settings.secret_key })
  end

  def unbind
    unless @exiting
      log(:warn, "Connection was closed unexpectedly. Trying to reconnect...")

      EM.add_timer(10) do
        reconnect(Settings.collector_host, Settings.collector_port)
      end
    end
  end

  def receive_data(data)
    @unpacker.feed_each(data) do |msg|
      unless msg.is_a?(Hash) && msg[:event]
        log(:warn, "Unknown data: #{msg}")
        next
      end

      parse_message(msg)
    end
  end

  def exit
    @exiting = true
    send_message(event: :exit, data: "Process is exiting.")
    stop_streams
  end

  private
  def parse_message(msg)
    case msg[:event]
    when "auth"
      log(:info, "Connection authenticated.")
    when "error"
      log(:error, "Error: #{msg[:data]}")
    when "activate"
      log(:info, "Node activated")
      msg.dig(:data, :accounts)&.each { |a|
        register_account(a)
      }
    when "register"
      register_account(msg[:data])
    when "unregister"
      unregister_account(msg[:data])
    when "heartbeat"
      log(:debug, "Heartbeat: #{msg[:data]}") if $VERBOSE
      send_message(msg)
    else
      log(:warn, "Unknown message: #{msg.inspect}")
    end
  end

  def register_account(account)
    if stream = @streams[account[:id]]
      stream.update(account)
    else
      stream = UserConnection.new(account)
      stream.start
      @streams[account[:id]] = stream
    end
  end

  def unregister_account(account)
    if stream = @streams.delete(account[:id])
      stream.stop
    end
  end

  def stop_streams
    @streams.each { |id, stream| stream.stop }
    @streams.clear
  end

  def send_message(data)
    send_data(data.to_msgpack)
  end

  def log(level, message)
    WorkerNode.logger.__send__(level, "CollectorConnection") { message }
  end
end
