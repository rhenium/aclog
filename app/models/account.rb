class Account < ActiveRecord::Base
  def user
    User.cached(user_id)
  end

  def twitter_user
    Rails.cache.fetch("twitter_user/#{user_id}", :expires_in => 1.hour) do
      client.user(user_id) rescue nil
    end
  end

  def import_favorites(id)
    result = client.status_activity(id)

    # favs ユーザー一覧回収
    Favorite.from_tweet_object(result)

    # favs ユーザー回収
    client.users(result.favoriters).each do |u|
      User.from_user_object(u)
    end

    # rts 回収・RTのステータスIDを取得する必要がある
    client.retweets(id).each do |status|
      Retweet.from_tweet_object(status)
    end
  end

  def client
    Twitter::Client.new(
      :consumer_key => Settings.consumer[consumer_version.to_i].key,
      :consumer_secret => Settings.consumer[consumer_version.to_i].secret,
      :oauth_token => oauth_token,
      :oauth_token_secret => oauth_token_secret)
  end

  def stats_api
    return {} unless twitter_user
    {
      favorites_count: twitter_user.favourites_count,
      listed_count: twitter_user.listed_count,
      followers_count: twitter_user.followers_count,
      tweets_count: twitter_user.statuses_count,
      friends_count: twitter_user.friends_count,
      listed_count: twitter_user.listed_count,
      bio: twitter_user.description
    }
  end
end
