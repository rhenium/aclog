Aclog::Application.routes.draw do
  constraints = {
    :id => /[0-9]+/,
    :user_id => /[0-9]+/,
    :screen_name => /[a-zA-Z0-9_]{1,20}/,
    :page => /[0-9]+/,
    :count => /[0-9]+/,
    :tweets => /(all|fav(orite[sd]?|(or)?ed|s)?|re?t(weet(s|ed)?|s)?)/,
    :order => /(fav(orite[sd]?|(or)?ed|s)?|re?t(weet(s|ed)?|s)?)/,
  }

  root :to => "main#index"

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
  get "/:screen_name/favs_from" => "users#from", :constraints => constraints, :defaults => {:event => "favorite"}
  get "/:screen_name/rts_from" => "users#from", :constraints => constraints, :defaults => {:event => "retweet"}

  # redirects
  get "/(users)/:screen_name/status(es)/:id" => redirect("/i/%{id}")
  get "/users/:screen_name" => redirect("/%{screen_name}")
  get "/users/:screen_name/discovered" => redirect("/%{screen_name}/discovered")
  get "/users/:screen_name/recent" => redirect("/%{screen_name}/timeline")
end
