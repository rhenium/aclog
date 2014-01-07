json.array! @result do |user_id, favorites_count, retweets_count|
  json.user_id user_id
  json.favorites_count favorites_count
  json.retweets_count retweets_count
end

