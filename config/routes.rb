Aclog::Application.routes.draw do
  constraints = {
    :id => /[0-9]+/,
    :user_id => /[0-9]+/,
    :screen_name => /[a-zA-Z0-9_]{1,20}/,
    :screen_name_b => /[a-zA-Z0-9_]{1,20}/,
    :page => /[0-9]+/,
    :count => /[0-9]+/,
    :tweets => /(all|fav(orite[sd]?|(or)?ed|s)?|re?t(weet(s|ed)?|s)?)/,
    :order => /(fav(orite[sd]?|(or)?ed|s)?|re?t(weet(s|ed)?|s)?)/,
  }

  root :to => "main#index"

  # static
  get "/about" => "main#about"
  get "/about/api" => "main#api"

  # internals
  get "/i/callback" => "sessions#callback"
  get "/i/logout" => "sessions#destroy"

  # other
  get "/i/best" => "i#best"
  get "/i/recent" => "i#recent"
  get "/i/timeline" => "i#timeline"

  get "/i/show" => "users#show"
  get "/i/:id" => "users#show", :constraints => constraints

  # i -- end
  get "/i(/:none)" => redirect("/")

  # user
  get "/users" => redirect("/")
  get "/users/best" => "users#best"
  get "/users/recent" => "users#recent"
  get "/users/timeline" => "users#timeline"
  get "/users/discovered" => "users#discovered"
  get "/users/info" => "users#info"
  get "/users/favorited_by" => "users#favorited_by"
  get "/users/retweeted_by" => "users#retweeted_by"
  get "/users/given_favorites_to" => "users#given_favorites_to"
  get "/users/given_retweets_to" => "users#given_retweets_to"

  get "/:screen_name(/:page)" => "users#best", :constraints => constraints
  get "/:screen_name/:order(/:page)" => "users#best", :constraints => constraints
  get "/:screen_name/recent(/:page)" => "users#recent", :constraints => constraints
  get "/:screen_name/recent/:order(/:page)" => "users#recent", :constraints => constraints
  get "/:screen_name/timeline(/:page)" => "users#timeline", :constraints => constraints
  get "/:screen_name/timeline/all(/:page)" => "users#timeline", :constraints => constraints, :defaults => {:all => "true"}
  get "/:screen_name/discovered(/:page)" => "users#discovered", :constraints => constraints
  get "/:screen_name/discovered/:tweets(/:page)" => "users#discovered", :constraints => constraints
  get "/:screen_name/info" => "users#info", :constraints => constraints
  get "/:screen_name/favorited_by(/:screen_name_b)" => "users#favorited_by", :constraints => constraints
  get "/:screen_name/retweeted_by(/:screen_name_b)" => "users#retweeted_by", :constraints => constraints
  get "/:screen_name/given_favorites_to(/:screen_name_b)" => "users#given_favorites_to", :constraints => constraints
  get "/:screen_name/given_retweets_to(/:screen_name_b)" => "users#given_retweets_to", :constraints => constraints

  # redirects
  get "(/users)/:screen_name/status(es)/:id" => redirect("/i/%{id}"), :constraints => constraints
  get "/users/:screen_name" => redirect("/%{screen_name}"), :constraints => constraints
  get "/users/:screen_name/most_favorited" => redirect("/%{screen_name}/favorite"), :constraints => constraints
  get "/users/:screen_name/most_retweeted" => redirect("/%{screen_name}/retweet"), :constraints => constraints
  get "/users/:screen_name/discovered" => redirect("/%{screen_name}/discovered"), :constraints => constraints
  get "/users/:screen_name/recent" => redirect("/%{screen_name}/timeline"), :constraints => constraints
  get "/users/:screen_name/favs_from(/:screen_name_b)" => redirect("/%{screen_name}/favorited_by/%{screen_name_b}"), :constraints => constraints
  get "/users/:screen_name/retweeted_by(/:screen_name_b)" => redirect("/%{screen_name}/retweeted_by/%{screen_name_b}"), :constraints => constraints
  get "/users/:screen_name/given_to(/:screen_name_b)" => redirect("/%{screen_name}/given_favorites_to/%{screen_name_b}"), :constraints => constraints
end
