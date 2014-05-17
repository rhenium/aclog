module Collector
  class EventQueue
    def initialize
      @queue_user = {}
      @queue_tweet = {}
      @queue_favorite = []
      @queue_retweet = []
      @queue_unfavorite = []
      @queue_delete = []
    end

    def flush
      ActiveRecord::Base.transaction do
        queue_user = @queue_user; @queue_user = {}
        User.create_or_update_bulk_from_json(queue_user.values)

        queue_tweet = @queue_tweet; @queue_tweet = {}
        Tweet.create_bulk_from_json(queue_tweet.values)

        queue_favorite = @queue_favorite; @queue_favorite = []
        Favorite.create_bulk_from_json(queue_favorite)

        queue_retweet = @queue_retweet; @queue_retweet = []
        Retweet.create_bulk_from_json(queue_retweet)

        queue_unfavorite = @queue_unfavorite; @queue_unfavorite = []
        Favorite.delete_bulk_from_json(queue_unfavorite)

        queue_delete = @queue_delete; @queue_delete = []
        if queue_delete.size > 0
          Tweet.destroy_bulk_from_json(queue_delete)
          Retweet.delete_bulk_from_json(queue_delete)
        end
      end
    end

    def push_user(user)
      @queue_user[user[:id]] = user
    end

    def push_tweet(tweet)
      push_user(tweet[:user])
      @queue_tweet[tweet[:id]] = tweet
    end

    def push_favorite(event)
      push_tweet(event[:target_object])
      push_user(event[:source])
      caching(:favorite, "#{event[:created_at]}-#{event[:source][:id]}-#{event[:target_object][:id]}") do
        @queue_favorite << event
      end
    end

    def push_retweet(status)
      push_user(status[:user])
      push_tweet(status[:retweeted_status])
      caching(:retweet, status[:id]) do
        @queue_retweet << status
      end
    end

    def push_unfavorite(event)
      push_tweet(event[:target_object])
      push_user(event[:source])
      caching(:unfavorite, "#{event[:created_at]}-#{event[:source][:id]}-#{event[:target_object][:id]}") do
        @queue_unfavorite << event
      end
    end

    def push_delete(delete)
      caching(:delete, delete[:delete][:status][:id]) do
        @queue_delete << delete
      end
    end

    private
    def caching(type, unique_key)
      @_cache ||= {}
      store = (@_cache[type] ||= {})

      unless store.key?(unique_key)
        yield
        store[unique_key] = true
        store.shift if store.size > Settings.collector.cache_size
      end
    end
  end
end
