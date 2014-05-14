module WorkerNode
  class EventQueue
    def initialize
      @cache = {}
      @queue = EM::Queue.new
    end

    def push(type, event)
      if event[:unique_id] && @cache.key?(event[:unique_id])
        WorkerNode.logger.debug("[EventQueue] Duplicate event: #{event[:unique_id]}")
      else
        @queue << [type, event]
        if event[:unique_id]
          @cache[event[:unique_id]] = true
          @cache.shift if @cache.size > Settings.cache_size
          # Hash#shift seems to delete the first item (CRuby 2.0.0-2.1.2) (ref: hash.c: rb_hash_shift)
        end
      end
    end

    def pop(&blk)
      @queue.pop &blk
    end
  end
end
