class Account < ActiveRecord::Base
  def user
    User.cached(user_id)
  end

  def twitter_user
    Rails.cache.fetch("twitter_user/#{user_id}", :expires_in => 1.hour) do
      client.user(user_id)
    end
  end

  def client
    Twitter::Client.new(
      :consumer_key => Settings.consumer[consumer_version.to_i].key,
      :consumer_secret => Settings.consumer[consumer_version.to_i].secret,
      :oauth_token => oauth_token,
      :oauth_token_secret => oauth_token_secret)
  end
end
