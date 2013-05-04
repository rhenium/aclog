json.(tweet, :id, :favorites_count, :retweets_count)

json.user_id tweet.user_id

json.favoriters tweet.favoriters.limit(@user_limit).pluck(:user_id)
json.retweeters tweet.retweeters.limit(@user_limit).pluck(:user_id)

