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
  get "/i" => redirect("/")
  get "/i/callback" => "sessions#callback"
  get "/i/logout" => "sessions#destroy"

  # other
  get "/i/show" => "i#show", :constraints => constraints

  get "/i/best" => "i#best"
  get "/i/recent" => "i#recent"
  get "/i/timeline" => "i#timeline"
  get "/i/:id" => "i#show", :constraints => constraints

  # user
  get "/users/best" => "users#best", :constraints => constraints
  get "/users/recent" => "users#recent", :constraints => constraints
  get "/users/timeline" => "users#timeline", :constraints => constraints
  get "/users/discovered" => "users#discovered", :constraints => constraints

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
  get "/(users)/:screen_name/status(es)/:id" => redirect("/i/%{id}")
  get "/users/:screen_name" => redirect("/%{screen_name}")
  get "/users/:screen_name/most_favorited" => redirect("/%{screen_name}/favorite")
  get "/users/:screen_name/most_retweeted" => redirect("/%{screen_name}/retweet")
  get "/users/:screen_name/discovered" => redirect("/%{screen_name}/discovered")
  get "/users/:screen_name/recent" => redirect("/%{screen_name}/timeline")
  get "/users/:screen_name/favs_from(/:screen_name_b)" => redirect("/%{screen_name}/favorited_by/%{screen_name_b}")
  get "/users/:screen_name/retweeted_by(/:screen_name_b)" => redirect("/%{screen_name}/retweeted_by/%{screen_name_b}")
  get "/users/:screen_name/given_to(/:screen_name_b)" => redirect("/%{screen_name}/given_favorites_to/%{screen_name_b}")
end
