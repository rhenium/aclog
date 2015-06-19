class EventChannel
  class << self
    def setup
      return if @dalli
      @dalli = Dalli::Client.new(Settings.memcached, namespace: "aclog-worker-node")
      @channel = EM::Channel.new
    end

    def push(data)
      raise ScriptError, "Call EventChannel.setup first" unless @dalli
      if id = data[:identifier]
        key, val = id.split("#", 2)
        cur = @dalli.get(key)
        if cur && (!val || (cur <=> val) > -1)
          WorkerNode.logger.debug("UniqueChannel") { "Duplicate event: #{key}" }
          return
        else
          @dalli.set(key, val || true)
        end
      end
      @channel << data
    end
    alias << push

    def subscribe(&blk)
      raise ScriptError, "Call EventChannel.setup first" unless @channel
      @channel.subscribe &blk
    end
  end
end
