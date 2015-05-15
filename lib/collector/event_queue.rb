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

      User.create_or_update_bulk_from_json(users)
      Tweet.create_bulk_from_json(tweets)
      Favorite.create_bulk_from_json(favorites)
      Retweet.create_bulk_from_json(retweets)
      Favorite.delete_bulk_from_json(unfavorites)

      if deletes.size > 0
        Tweet.destroy_bulk_from_json(deletes)
        Retweet.delete_bulk_from_json(deletes)
      end

      tweet_ids = favorites.map {|f| f[:target_object][:id] }
      if tweet_ids.size > 0
        Tweet.where(id: tweet_ids).each do |tweet|
          Notification.try_notify_favorites(tweet)
        end
      end

      unauthorizeds.each do |a|
        account = Account.find(a[:id])
        account.verify_token!
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
        key, val = id.split("#", 2)
        cur = @dalli.get(id)
        if !cur || (val && (cur <=> val) == -1) # not found or new
          @dalli.set(key, true || value)
          yield
        end
      else
        yield
      end
    end
  end
end
