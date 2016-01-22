module Collector
  class EventQueue
    def initialize(dalli)
      @dalli = dalli
      @queue_mutex = Mutex.new

      @queue_user = []
      @queue_tweet = []
      @queue_favorite = []
      @queue_retweet = []
      @queue_unfavorite = []
      @queue_delete = []
      @queue_unauthorized = []
    end

    def self.start(dalli)
      instance = self.new(dalli)
      EM.add_periodic_timer(Settings.collector.flush_interval) do
        instance.flush
      end
      instance
    end

    def flush
      @queue_mutex.lock
      begin
        users, @queue_user = @queue_user, []
        tweets, @queue_tweet = @queue_tweet, []
        favorites, @queue_favorite = @queue_favorite, []
        retweets, @queue_retweet = @queue_retweet, []
        unfavorites, @queue_unfavorite = @queue_unfavorite, []
        deletes, @queue_delete = @queue_delete, []
        unauthorizeds, @queue_unauthorized = @queue_unauthorized, []
      ensure
        @queue_mutex.unlock
      end

      users.reverse!.uniq! { |i| i[:id] }
      tweets.reverse!.uniq! { |i| i[:id] }

      User.create_or_update_bulk_from_json(users)
      Tweet.create_bulk_from_json(tweets)
      Favorite.create_bulk_from_json(favorites)
      Favorite.delete_bulk_from_json(unfavorites) # TODO: race?
      Retweet.create_bulk_from_json(retweets)

      if deletes.size > 0
        Tweet.destroy_bulk_from_json(deletes)
        Retweet.delete_bulk_from_json(deletes)
      end

      if Settings.notification.enabled
        NotificationQueue.push(favorites.map { |f| f.dig(:target_object, :id) })
      end

      if unauthorizeds.size > 0
        AccountTokenVerificationJob.perform_later(unauthorizeds.map { |u| u[:id] })
      end
    end

    def push_user(msg)
      cache(msg) do
        @queue_user << msg[:data]
      end
    end

    def push_tweet(msg)
      cache(msg) do
        @queue_tweet << msg[:data]
      end
    end

    def push_retweet(msg)
      cache(msg) do
        @queue_retweet << msg[:data]
      end
    end

    def push_favorite(msg)
      cache(msg) do
        @queue_favorite << msg[:data]
      end
    end

    def push_unfavorite(msg)
      cache(msg) do
        @queue_unfavorite << msg[:data]
      end
    end

    def push_delete(msg)
      cache(msg) do
        @queue_delete << msg[:data]
      end
    end

    def push_unauthorized(unauthorized)
      @queue_mutex.synchronize { @queue_unauthorized << unauthorized[:data] }
    end

    private
    def cache(object)
      if id = object[:identifier]
        if version = object[:version]
          cur = @dalli.get(id)
          if cur && cur >= version
            Rails.logger.debug("EventQueue") { "dup: #{id}/#{cur} <=> #{version}" } if $VERBOSE
            return
          else
            @dalli.set(id, version)
          end
        end
      end

      @queue_mutex.synchronize { yield }
    end
  end
end
