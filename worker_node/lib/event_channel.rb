class EventChannel
  class << self
    def setup
      return if @dalli
      @dalli = Dalli::Client.new(Settings.memcached, namespace: "aclog-worker-node:")
      @channel = EM::Channel.new
    end

    def push(data)
      raise ScriptError, "Call EventChannel.setup first" unless @dalli
      if id = data[:identifier]
        if @dalli.get(id)
          WorkerNode.logger.debug("UniqueChannel") { "Duplicate event: #{id}" }
          return
        else
          @dalli.set(id, true)
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
