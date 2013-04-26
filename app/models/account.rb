class Account < ActiveRecord::Base
  has_one :user

  def self.create_or_update(hash)
    account = where(user_id: hash[:user_id]).first_or_initialize
    account.oauth_token = hash[:oauth_token]
    account.oauth_token_secret = hash[:oauth_token_secret]
    account.consumer_version = hash[:consumer_version]
    account.save if account.changed?
    account
  end

  def client
    Twitter::Client.new(
      consumer_key: Settings.consumer[consumer_version.to_i].key,
      consumer_secret: Settings.consumer[consumer_version.to_i].secret,
      oauth_token: oauth_token,
      oauth_token_secret: oauth_token_secret)
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
    client.retweets(id, count: 100).each do |status|
      Retweet.from_tweet_object(status)
    end
  end
end
