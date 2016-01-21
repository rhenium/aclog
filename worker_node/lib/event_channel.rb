class EventChannel
  class << self
    def setup
      return if @dalli
      @dalli = Dalli::Client.new(Settings.memcached, namespace: "aclog-worker-node")
      @channel = EM::Channel.new
    end

    def push(data)
      if id = data[:identifier]
        if version = data[:version]
          cur = @dalli.get(id)
          if cur && cur >= version
            WorkerNode.logger.debug("UniqueChannel") { "dup: #{id}/#{cur} <=> #{version}" } if $VERBOSE
            return
          else
            @dalli.set(id, version)
          end
        end
      end

      @channel << data
    end
    alias << push

    def subscribe(&blk)
      @channel.subscribe &blk
    end
  end
end
