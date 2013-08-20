json.(tweet, :id, :favorites_count, :retweets_count)

json.user_id tweet.user_id

user_limit = Integer(params[:limit]) rescue nil

json.favoriters tweet.favorites.limit(user_limit).pluck(:user_id)
json.retweeters tweet.retweets.limit(user_limit).pluck(:user_id)

