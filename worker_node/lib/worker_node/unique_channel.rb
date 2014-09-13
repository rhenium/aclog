module WorkerNode
  class UniqueChannel
    def initialize(&blk)
      @cache = {}
      @channel = EM::Channel.new
      @block = blk
    end

    def push(type, event)
      u = @block.call(event)
      if @cache.key?(u)
        WorkerNode.logger.debug("[UniqueChannel] Duplicate event: #{u}")
      else
        @channel.push [type, event]
        if u
          @cache[u] = true
          @cache.shift if @cache.size > Settings.cache_size
          # Hash#shift seems to delete the first item (CRuby 2.0.0-2.1.2) (ref: hash.c: rb_hash_shift)
        end
      end
    end

    def subscribe(&blk)
      @channel.subscribe &blk
    end
  end
end
