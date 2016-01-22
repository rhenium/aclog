module Collector
  class EventQueue
    def initialize
      @dalli = Dalli::Client.new(Settings.cache.memcached, namespace: "aclog-collector:")
      @queue_mutex = Mutex.new

      @queue_user = Queue.new
      @queue_tweet = Queue.new
      @queue_favorite = Queue.new
      @queue_retweet = Queue.new
      @queue_unfavorite = Queue.new
      @queue_delete = Queue.new
      @queue_unauthorized = Queue.new
    end

    def flush
      users = tweets = favorites = retweets = unfavorites = deletes = unauthorizeds = nil

      @queue_mutex.synchronize do
        users = @queue_user.size.times.map { @queue_user.deq }
        tweets = @queue_tweet.size.times.map { @queue_tweet.deq }
        favorites = @queue_favorite.size.times.map { @queue_favorite.deq }
        retweets = @queue_retweet.size.times.map { @queue_retweet.deq }
        unfavorites = @queue_unfavorite.size.times.map { @queue_unfavorite.deq }
        deletes = @queue_delete.size.times.map { @queue_delete.deq }
        unauthorizeds = @queue_unauthorized.size.times.map { @queue_unauthorized.deq }
      end

      users.reverse!.uniq! {|i| i[:id] }
      tweets.reverse!.uniq! {|i| i[:id] }

      User.create_or_update_bulk_from_json(users)
      Tweet.create_bulk_from_json(tweets)
      Favorite.create_bulk_from_json(favorites)
      Retweet.create_bulk_from_json(retweets)
      Favorite.delete_bulk_from_json(unfavorites)

      if deletes.size > 0
        Tweet.destroy_bulk_from_json(deletes)
        Retweet.delete_bulk_from_json(deletes)
      end

      if Settings.notification.enabled
        tweet_ids = favorites.map {|f| f.dig(:target_object, :id) }
        NotificationQueue.push(tweet_ids)
      end

      if unauthorizeds.size > 0
        AccountTokenVerificationJob.perform_later(unauthorizeds.map {|u| u[:id] })
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
      @queue_unauthorized << unauthorized[:data]
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

      yield
    end
  end
end
