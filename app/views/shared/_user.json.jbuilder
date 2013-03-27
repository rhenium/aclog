json.(user, :id, :screen_name, :name, :profile_image_url)
if @include_user_stats && user.registered?
  json.stats user.stats
end
