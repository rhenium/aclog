json.(tweet, :id, :favorites_count, :retweets_count)

json.user_id tweet.user_id

json.favoriters tweet.favoriters.limit(@user_limit).pluck(:user_id)
json.retweeters tweet.retweeters.limit(@user_limit).pluck(:user_id)

if /^\/users\// =~ request.fullpath
  # deprecated API
  json.favorites do
    json.array! tweet.favorites.includes(:user).limit(@user_limit) do |item|
      json.(item, :user)
    end
  end
  json.retweets do
    json.array! tweet.retweets.includes(:user).limit(@user_limit) do |item|
      json.(item, :user)
    end
  end
end
