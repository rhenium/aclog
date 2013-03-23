json.(item, :id, :text, :source, :tweeted_at, :favorites_count, :retweets_count)

json.user do |json|
  json.partial! "shared/user", :user => item.user
end

unless @trim_user
  json.favorites item.favorites.order("id") do |json, favorite|
    json.user do |json|
      json.partial! "shared/user", :user => favorite.user || User.new
    end
  end
  json.retweets item.retweets.order("id") do |json, retweet|
    json.id retweet.id
    json.user do |json|
      json.partial! "shared/user", :user => retweet.user || User.new
    end
  end
end
