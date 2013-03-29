class Account < ActiveRecord::Base
  def user
    User.cached(user_id)
  end

  def twitter_user
    Rails.cache.fetch("twitter_user/#{user_id}", :expires_in => 1.hour) do
      client.user(user_id) rescue nil
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
