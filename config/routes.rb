Rails.application.routes.draw do
  get "/i/status" => redirect("/about/status")
  get "/:screen_name/discovered_by" => redirect("/%{screen_name}/stats")
  get "/:screen_name/discovered_users" => redirect("/%{screen_name}/stats")

  mount Api => "/api"

  root "about#index"

  get "/about/api" =>                           "apidocs#index",                    as: "about_api"
  get "/about/api/:method/:namespace/:path" =>  "apidocs#endpoint",                 as: "about_api_endpoint", constraints: { namespace: /[\w\/]+/ }
  get "/about/status" =>                        "about#status",                     as: "status"

  get "/settings" =>                            "settings#index",                   as: "settings"
  post "/settings/update" =>                    "settings#update",                  as: "settings_update"
  get "/settings/confirm_deactivation" =>       "settings#confirm_deactivation"
  post "/settings/deactivate" =>                "settings#deactivate"

  post "/i/login" =>                            "sessions#new",                     as: "login"
  get "/i/callback" =>                          "sessions#create",                  as: "sessions_create"
  post "/i/logout" =>                           "sessions#destroy",                 as: "logout"

  get "/i/optout" =>                            "optout#index",                     as: "optout"
  post "/i/optout" =>                           "optout#create",                    as: "optout_create"
  get "/i/optout/callback" =>                   "optout#callback",                  as: "optout_callback"
  delete "/i/optout" =>                         "optout#destroy",                   as: "optout_destroy"

  get "/i/:id" =>                               "tweets#show",                      as: "tweet", constraints: { id: /\d+/ }
  post "/i/:id" =>                              "tweets#update",                    as: "update", constraints: { id: /\d+/ }

  get "/i/best" =>                              "tweets#all_best",                  as: "best"
  get "/i/timeline" =>                          "tweets#all_timeline",              as: "timeline"
  get "/i/filter" =>                            "tweets#filter",                    as: "filter"

  scope "/i/api" do
    post "/tweets/update" => "internal/tweets#update"
    get "/tweets/:action", controller: "internal/tweets"
    get "/users/:action",  controller: "internal/users"
    get "/about/:action",  controller: "internal/about"
  end

  # User pages
  scope "/:screen_name" do
    get "/" =>                                  "tweets#user_index",                as: "user"
    get "/best" =>                              "tweets#user_best",                 as: "user_best"
    get "/timeline" =>                          "tweets#user_timeline",             as: "user_timeline"
    get "/favorites" =>                         "tweets#user_favorites",            as: "user_favorites"
    get "/favorited_by/:source_screen_name" =>  "tweets#user_favorited_by",         as: "user_favorited_by_user"
    get "/stats" =>                             "users#stats",                      as: "user_stats"
  end

  get "*unmatched_route" =>                     "application#routing_error"
end

