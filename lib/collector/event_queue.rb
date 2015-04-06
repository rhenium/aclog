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

      favorites.each do |event|
        Notification.try_notify_favorites(id: event[:target_object][:id],
                                          user_id: event[:target_object][:user][:id],
                                          favorites_count: event[:target_object][:favorite_count])
      end

      unauthorizeds.each do |a|
        account = Account.find(a[:id])
        account.verify_token!
      end
    end

    def push_user(user)
      cache(user.merge!(identifier: user[:id])) do
        @queue_user << user
      end
    end

    def push_tweet(tweet)
      cache(tweet.merge!(identifier: "tweet-#{tweet[:id]}-#{tweet[:favorite_count]}-#{tweet[:retweet_count]}")) do
        @queue_tweet << tweet
      end
    end

    def push_favorite(event)
      cache(event.merge!(identifier: "favorite-#{event[:timestamp_ms]}-#{event[:source][:id]}-#{event[:target_object][:id]}")) do
        push_tweet(event[:target_object])
        push_user(event[:source])
        @queue_favorite << event
      end
    end

    def push_retweet(status)
      cache(status.merge!(identifier: "retweet-#{status[:id]}")) do
        push_user(status[:user])
        push_tweet(status[:retweeted_status])
        @queue_retweet << status
      end
    end

    def push_unfavorite(event)
      cache(event.merge!(identifier: "unfavorite-#{event[:timestamp_ms]}-#{event[:source][:id]}-#{event[:target_object][:id]}")) do
        push_tweet(event[:target_object])
        push_user(event[:source])
        @queue_unfavorite << event
      end
    end

    def push_delete(delete)
      cache(delete.merge(identifier: "delete-#{delete[:delete][:status][:id]}")) do
        @queue_delete << delete
      end
    end

    def push_unauthorized(unauthorized)
      @queue_unauthorized << unauthorized
    end

    private
    def cache(object)
      if id = object[:identifier]
        unless @dalli.get(id)
          @dalli.set(id, true)
          yield
        end
      else
        yield
      end
    end
  end
end
