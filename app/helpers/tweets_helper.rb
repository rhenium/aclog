module TweetsHelper
  def favorites_truncate_count
    params[:full] == "true" ? Settings.tweets.favorites.max : Settings.tweets.favorites.count
  end

  def favorites_truncated?(tweet)
    (favorites_truncate_count || Float::INFINITY) < [tweet.favorites_count, tweet.retweets_count].max
  end
end
