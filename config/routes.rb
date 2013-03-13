Aclog::Application.routes.draw do
  constraints = {
    :id => /[0-9]+/,
    :screen_name => /[a-zA-Z0-9_]{1,20}/,
    :page => /[0-9]+/,
  }

  root :to => "main#index"
  get "i/callback" => "sessions#callback"
  get "i/logout" => "sessions#destroy"

  get "i/:id" => "i#show", :constraints => constraints
  get ":screen_name/status(es)/:id" => "i#show", :constraints => constraints

  get ":screen_name(/:page)" => "users#best", :constraints => constraints
  get ":screen_name/my(/:page)" => "users#my", :constraints => constraints
  get ":screen_name/discovered(/:page)" => "users#my", :constraints => constraints
  get ":screen_name/timeline(/:page)" => "users#timeline", :constraints => constraints
  get ":screen_name/recent(/:page)" => "users#recent", :constraints => constraints
  get ":screen_name/info(/:page)" => "users#info", :constraints => constraints
end
