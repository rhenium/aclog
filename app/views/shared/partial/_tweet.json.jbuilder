json.(tweet, :id, :text, :source, :tweeted_at, :favorites_count, :retweets_count)

json.user do
  json.id tweet.user_id
  if include_user?
    json.partial! "shared/partial/user", user: tweet.user
  end
end

render_actions = -> name, data, render_id do
  json.__send__(name, data.includes(:user).limit(user_limit).load) do |action|
    json.id action.id if render_id
    json.user do
      json.id action.user_id
      if include_user?
        json.partial! "shared/partial/user", user: action.user
      end
    end
  end
end

render_actions.call(:favorites, tweet.favorites, false)
render_actions.call(:retweets, tweet.retweets, true)

