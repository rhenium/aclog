if authorized_to_show_user?(tweet.user)
  json.id_str tweet.id.to_s
  
  json.user do
    json.(tweet.user, :name, :screen_name, :profile_image_url)
  end
  
  json.(tweet, :text, :tweeted_at, :source, :favorites_count, :retweets_count, :reactions_count)
  
  json.favorites []
  json.retweets []
  json.allowed true
else
  json.tweeted_at
  json.allowed false
end
