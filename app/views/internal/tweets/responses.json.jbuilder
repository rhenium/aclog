apply = ->(property, users) do
  json.__send__(property, @tweet.__send__(users)) do |u|
    if current_user == @tweet.user || authorized?(u)
      json.name u.name
      json.screen_name u.screen_name
      json.profile_image_url u.profile_image_url
      json.allowed true
    else
      json.allowed false
    end
  end
end

apply.(:favorites, :favoriters)
apply.(:retweets, :retweeters)
