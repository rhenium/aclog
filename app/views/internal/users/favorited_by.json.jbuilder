tops = @data.take(Settings.users.count)
cached_users = User.find(tops.map {|k, v| k }).map {|user| [user.id, user] }.to_h

all_reactions = @data.inject(0) {|sum, (k, v)| sum + v }
json.users_count @data.size
json.reactions_count all_reactions
json.users(tops) do |user_id, count|
  u = cached_users[user_id]
  json.user_id user_id
  json.count count
  json.name u.name
  json.screen_name u.screen_name
  json.profile_image_url u.profile_image_url
end
