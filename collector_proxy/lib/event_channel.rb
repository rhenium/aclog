class EventChannel
  class << self
    def setup
      return if @dalli
      @dalli = Dalli::Client.new(Settings.memcached, namespace: "aclog-collector-proxy")
      @queue = []
      @subscribers = {}
    end

    def push(data)
      raise ScriptError, "Call EventChannel.setup first" unless @dalli
      if id = data[:identifier]
        key, val = id.split("#", 2)
        cur = @dalli.get(key)
        if cur && (!val || (cur <=> val) > -1)
          CollectorProxy.logger.debug("UniqueChannel") { "Duplicate event: #{key}" }
          return
        else
          @dalli.set(key, val || true)
        end
      end
      if @subscribers.size > 0
        @subscribers.values.each do |blk|
          blk.call(data)
        end
      else
        @queue << data
      end
    end
    alias << push

    def subscribe(&blk)
      @subscribers[blk.__id__] = blk
      while @queue.size > 0
        blk.call(@queue.shift)
      end
      blk.__id__
    end

    def unsubscribe(id)
      @subscribers.delete(id)
    end
  end
end
