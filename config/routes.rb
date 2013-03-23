Aclog::Application.routes.draw do
  constraints = {
    :id => /[0-9]+/,
    :screen_name => /[a-zA-Z0-9_]{1,20}/,
    :page => /[0-9]+/,
  }
  get "/404" => "errors#error_404"
  get "/500" => "errors#error_500"

  root :to => "main#index"

  get "/i/callback" => "sessions#callback"
  get "/i/logout" => "sessions#destroy"

  get "/i/best" => "i#best"
  get "/i/recent" => "i#recent"

  get "/i/:id" => "users#show", :constraints => constraints
  get "/(users)/:screen_name/status(es)/:id" => redirect("/i/%{id}")

  get "/:screen_name(/:page)" => "users#best", :constraints => constraints
  get "/:screen_name/best" => redirect("/%{screen_name}")
  get "/users/:screen_name" => redirect("/%{screen_name}")

  get "/:screen_name/discovered(/:page)" => "users#my", :constraints => constraints
  get "/:screen_name/my(/:page)" => "users#my", :constraints => constraints
  get "/users/:screen_name/discovered" => redirect("/%{screen_name}/discovered")

  get "/:screen_name/timeline(/:page)" => "users#timeline", :constraints => constraints
  get "/:screen_name/timeline/all(/:page)" => "users#timeline", :constraints => constraints, :defaults => {:tweets => "all"}
  get "/users/:screen_name/recent" => redirect("/%{screen_name}/timeline")

  get "/:screen_name/recent(/:page)" => "users#recent", :constraints => constraints
end
