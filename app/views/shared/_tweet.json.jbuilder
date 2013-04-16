json.(item, :id, :text, :source, :tweeted_at, :favorites_count, :retweets_count)

json.user do
  json.id item.user_id
  if @include_user
    json.partial! "shared/user", :user => item.user
  end
end

render_actions = -> name, data, render_id do
  n = 0
  json.__send__(name, data) do |action|
    json.id action.id if render_id
    json.user do
      json.id action.user_id
      if @include_user && (!user_limit || n < user_limit)
        json.partial! "shared/user", :user => action.user
      end
    end
    n += 1
  end
end

render_actions.call(:favorites, item.favorites.includes(:user), false)
render_actions.call(:retweets, item.retweets.includes(:user), true)

