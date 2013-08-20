module TweetsHelper
  def html_favoriters_limit
    if params[:action] == "show"
      if params[:full] == "true"
        nil
      else
        Settings.tweets.users.count_lot
      end
    else
      Settings.tweets.users.count_default
    end
  end

  def html_favoriters_truncated?(tweet)
    tr = html_favoriters_limit || Float::INFINITY
    tr < tweet.favorites_count || tr < tweet.retweets_count
  end
end
