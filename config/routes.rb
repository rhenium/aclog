Aclog::Application.routes.draw do
  constraints = {
    :id => /[0-9]+/,
    :user_id => /[0-9]+/,
    :screen_name => /[a-zA-Z0-9_]{1,20}/,
    :page => /[0-9]+/,
    :count => /[0-9]+/,
    :tweets => /(all|favorite|retweet)/
  }

  root :to => "main#index"

  get "/i/callback" => "sessions#callback"
  get "/i/logout" => "sessions#destroy"

  get "/i/best" => "i#best"
  get "/i/recent" => "i#recent"

  get "/i/show" => "i#show", :constraints => constraints
  get "/users/best" => "users#best", :constraints => constraints
  get "/users/recent" => "users#recent", :constraints => constraints
  get "/users/timeline" => "users#timeline", :constraints => constraints
  get "/users/discovered" => "users#discovered", :constraints => constraints

  get "/i/:id" => "i#show", :constraints => constraints

  get "/:screen_name(/:page)" => "users#best", :constraints => constraints
  get "/:screen_name/best" => redirect("/%{screen_name}")

  get "/:screen_name/recent(/:page)" => "users#recent", :constraints => constraints

  get "/:screen_name/timeline(/:page)" => "users#timeline", :constraints => constraints
  get "/:screen_name/timeline/:tweets(/:page)" => "users#timeline", :constraints => constraints

  get "/:screen_name/discovered(/:page)" => "users#discovered", :constraints => constraints
  get "/:screen_name/discovered/:tweets(/:page)" => "users#discovered", :constraints => constraints

  get "/(users)/:screen_name/status(es)/:id" => redirect("/i/%{id}")
  get "/users/:screen_name" => redirect("/%{screen_name}")
  get "/users/:screen_name/discovered" => redirect("/%{screen_name}/discovered")
  get "/users/:screen_name/recent" => redirect("/%{screen_name}/timeline")
end
