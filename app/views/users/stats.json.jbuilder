apply = ->(name, list) do
  json.__send__(name, list.sort_by {|k, v| -v }) do |user_id, count|
    u = @cached_users[user_id]
    if authorized_to_show_user?(u)
      json.user_id u.id
      json.name u.name
      json.screen_name u.screen_name
      json.profile_image_url u.profile_image_url
      json.allowed true
    else
      json.allowed false
    end
    json.count count
  end
end

apply.(:discovered_by, @discovered_by)
apply.(:discovered_users, @discovered_users)
