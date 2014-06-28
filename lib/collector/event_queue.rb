module Collector
  class EventQueue
    def initialize
      @queue_user = {}
      @queue_tweet = {}
      @queue_favorite = []
      @queue_retweet = []
      @queue_unfavorite = []
      @queue_delete = []
      @queue_unauthorized = []
    end

    def flush
      queue_user = @queue_user; @queue_user = {}
      queue_tweet = @queue_tweet; @queue_tweet = {}
      queue_favorite = @queue_favorite; @queue_favorite = []
      queue_retweet = @queue_retweet; @queue_retweet = []
      queue_unfavorite = @queue_unfavorite; @queue_unfavorite = []
      queue_delete = @queue_delete; @queue_delete = []
      queue_unauthorized = @queue_unauthorized; @queue_unauthorized = []

      User.create_or_update_bulk_from_json(queue_user.values)
      Tweet.create_bulk_from_json(queue_tweet.values)
      Favorite.create_bulk_from_json(queue_favorite)
      Retweet.create_bulk_from_json(queue_retweet)
      Favorite.delete_bulk_from_json(queue_unfavorite)

      if queue_delete.size > 0
        Tweet.destroy_bulk_from_json(queue_delete)
        Retweet.delete_bulk_from_json(queue_delete)
      end

      queue_favorite.each do |event|
        Notification.try_notify_favorites(id: event[:target_object][:id],
                                          user_id: event[:target_object][:user][:id],
                                          favorites_count: event[:target_object][:favorite_count])
      end

      queue_unauthorized.each do |a|
        account = Account.find(a[:id])
        account.verify_token!
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
      caching(:favorite, "#{event[:created_at]}-#{event[:source][:id]}-#{event[:target_object][:id]}") do
        push_tweet(event[:target_object])
        push_user(event[:source])
        @queue_favorite << event
      end
    end

    def push_retweet(status)
      caching(:retweet, status[:id]) do
        push_user(status[:user])
        push_tweet(status[:retweeted_status])
        @queue_retweet << status
      end
    end

    def push_unfavorite(event)
      caching(:unfavorite, "#{event[:created_at]}-#{event[:source][:id]}-#{event[:target_object][:id]}") do
        push_tweet(event[:target_object])
        push_user(event[:source])
        @queue_unfavorite << event
      end
    end

    def push_delete(delete)
      caching(:delete, delete[:delete][:status][:id]) do
        @queue_delete << delete
      end
    end

    def push_unauthorized(unauthorized)
      @queue_unauthorized << unauthorized
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
