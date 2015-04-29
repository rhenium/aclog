class WorkerNodeConnection < EM::Connection
  attr_reader :connection_id
  attr_accessor :activated_time

  @@_id = 0

  def initialize
    @unpacker = MessagePack::Unpacker.new(symbolize_keys: true)
    @connection_id = (@@_id += 1)
    @authenticated = false
    @closing = false
    @heartbeats = Set.new
    @activated_time = nil
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
        log(:warn, "Connection was closed unexpectedly.")
        NodeManager.unregister(self)
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

  def register_account(account)
    send_message(event: "register", data: account)
  end

  def unregister_account(account)
    send_message(event: "unregister", data: account)
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
      NodeManager.unregister(self)
    when "heartbeat"
      log(:debug, "Heartbeat reply: #{msg[:data]}")
      @heartbeats.delete(msg[:data])
    else
      EventChannel << msg
    end
  end

  def authenticate_node(data)
    if data.key?(:secret_key) && Settings.secret_key == data[:secret_key]
      log(:info, "Connection authenticated.")
      send_message(event: :auth, data: nil)
      @authenticated = true
      @heartbeat_timer = EM.add_periodic_timer(10, &method(:heartbeat))
      NodeManager.register(self)
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

  def send_message(data)
    send_data(data.to_msgpack)
  end

  def log(level, message)
    CollectorProxy.logger.__send__(level, "WorkerNodeConnection(##{@connection_id})") { message }
  end
end
