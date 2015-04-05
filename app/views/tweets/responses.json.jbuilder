apply = ->(property, users) do
  json.__send__(property, @tweet.__send__(users)) do |u|
    if authorized_to_show_user?(u)
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
