module TweetsHelper
  def user_limit
    if request.format == :json
      if params[:limit]
        params[:limit].to_i
      else
        nil
      end
    else
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
  end

  def user_truncated?(tweet)
    tr = user_limit || Float::INFINITY
    tr < tweet.favorites_count || tr < tweet.retweets_count
  end
end
