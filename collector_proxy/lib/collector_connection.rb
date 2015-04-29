class CollectorConnection < EM::Connection
  @@_id = 0

  def initialize
    @@_id += 1
    @unpacker = MessagePack::Unpacker.new(symbolize_keys: true)
    @authenticated = false
    @closing = false
    @heartbeats = Set.new
    @subscribe_id = nil
  end

  def post_init
    # do nothing
  end

  def unbind
    @heartbeat_timer.cancel if @heartbeat_timer
    if @closing
      log(:info, "Connection was closed.")
    else
      if @authenticated
        log(:info, "Connection was closed unexpectedly.")
        EventChannel.unsubscribe(@subscribe_id)
      end
    end
  end

  def receive_data(data)
    @unpacker.feed_each(data) do |msg|
      unless msg.is_a?(Hash) && msg[:event]
        log(:warn, "Unknown message: #{msg}")
        send_message(event: :error, data: "Unknown message.")
        close_connection_after_writing
        return
      end

      parse_message(msg)
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
    when "exit"
      log(:info, "Closing this connection...")
      @closing = true
      EventChannel.unsubscribe(@subscribe_id)
    when "heartbeat"
      log(:debug, "Heartbeat reply: #{msg[:data][:id]}")
      @heartbeats.delete(msg[:data][:id])
    when "register"
      log(:debug, "Registered account ##{msg[:data][:id]}")
      NodeManager.register_account(msg[:data])
    when "unregister"
      log(:debug, "Unregistered account ##{msg[:data][:id]}")
      NodeManager.unregister_account(msg[:data])
    when "stats"
      log(:debug, "Stats request")
      # TODO
    end
  end

  def authenticate_node(data)
    if data.key?(:secret_key) && Settings.secret_key == data[:secret_key]
      log(:info, "Connection authenticated.")
      send_message(event: :auth, data: nil)
      @authenticated = true
      @heartbeat_timer = EM.add_periodic_timer(10, &method(:heartbeat))
      @subscribe_id = EventChannel.subscribe {|message| send_message(message) }
    else
      log(:warn, "Invalid secret_key: #{data[:secret_key].inspect}")
      send_message(event: :error, data: "Invalid secret_key.")
      @closing = true
      close_connection_after_writing
    end
  end

  def heartbeat
    if @heartbeats.size > 2 # 30 sec
      log(:warn, "Node is dead.")
      @heartbeat_timer.cancel
      @heartbeat_timer = nil
      @closing = true
      close_connection_after_writing
      return
    end

    id = Time.now.to_i
    @heartbeats << id
    send_message(event: :heartbeat, data: { id: id, stats: stats })
  end

  def stats
    NodeManager.stats
  end

  def send_message(data)
    send_data(data.to_msgpack)
  end

  def log(level, message)
    CollectorProxy.logger.__send__(level, "CollectorConnection(##{@@_id})") { message }
  end
end
