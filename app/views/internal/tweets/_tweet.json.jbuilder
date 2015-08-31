if !authorized?(tweet.user)
  json.allowed false

  json.tweeted_at tweet.tweeted_at
  json.text "ユーザーはツイートを非公開にしています"
elsif tweet.user.opted_out?
  json.id_str tweet.id.to_s
  json.allowed false
  json.opted_out true

  json.user do
    json.(tweet.user, :name, :screen_name, :profile_image_url)
  end
  
  json.tweeted_at tweet.tweeted_at
  json.text "ユーザーはオプトアウトしているため表示されません"
else
  json.id_str tweet.id.to_s
  json.allowed true
  json.opted_out false

  json.user do
    json.(tweet.user, :name, :screen_name, :profile_image_url)
  end
  
  json.(tweet, :text, :tweeted_at, :source, :favorites_count, :retweets_count, :reactions_count)

  if tweet.reactions_count <= 20
    json.partial! "responses", tweet: tweet
    json.include_reactions true
  end
end
