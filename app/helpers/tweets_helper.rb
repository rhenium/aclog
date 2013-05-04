module TweetsHelper
  def user_truncated?(tweet)
    tr = @user_limit || Float::INFINITY
    tr < tweet.favorites_count || tr < tweet.retweets_count
  end
end
