json.(tweet, :id, :favorites_count, :retweets_count)

json.user_id tweet.user_id

json.favoriters tweet.favorites.limit(@user_limit).pluck(:user_id)
json.retweeters tweet.retweets.limit(@user_limit).pluck(:user_id)

