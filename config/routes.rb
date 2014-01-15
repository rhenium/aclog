Aclog::Application.routes.draw do
  root to: "about#index"

  # JSON API
  scope "/api", format: false, defaults: { format: "json" } do
    get "/users/:action.json",  controller: "users"
    get "/tweets/:action.json", controller: "tweets"
  end

  # Internals / SessionsController
  get "/i/callback" =>                          "sessions#create"
  get "/i/logout" =>                            "sessions#destroy",                 as: "logout"

  get "/i/:id" =>                               "tweets#show",                      as: "tweet", constraints: { id: /\d+/ }

  get "/i/settings" =>                          "settings#index",                   as: "settings"
  post "/i/settings/update" =>                  "settings#update"
  get "/i/settings/confirm_deactivation" =>     "settings#confirm_deactivation"
  post "/i/settings/deactivate" =>              "settings#deactivate"

  get "/i/best" =>                              "tweets#all_best",                  as: "best"
  get "/i/recent" =>                            "tweets#all_recent",                as: "recent"
  get "/i/timeline" =>                          "tweets#all_timeline",              as: "timeline"
  get "/i/search" =>                            "tweets#search",                    as: "search"

  get "/about" =>                               "about#about",                      as: "about"
  get "/about/api" =>                           "about#api",                        as: "about_api"
  get "/about/api/docs" =>                      "apidocs#index",                    as: "api_docs"
  get "/about/api/docs/:resource/:name" =>      "apidocs#endpoint",                 as: "api_docs_endpoint"

  get "/help/search" =>                         "help#search",                      as: "help_search"

  # User pages
  scope "/:screen_name" do
    get "/" =>                                  "tweets#index",                     as: "user"
    get "/best" =>                              "tweets#best",                      as: "user_best"
    get "/recent" =>                            "tweets#recent",                    as: "user_recent"
    get "/timeline" =>                          "tweets#timeline",                  as: "user_timeline"
    get "/discoveries" =>                       "tweets#discoveries",               as: "user_discoveries"
    get "/favorites" =>                         "tweets#favorites",                 as: "user_favorites"
    get "/retweets" =>                          "tweets#retweets",                  as: "user_retweets"
    get "/discovered_by/:screen_name_b" =>      "tweets#discovered_by",             as: "user_discovered_by_user"

    get "/discovered_by" =>                     "users#discovered_by",              as: "user_discovered_by"
    get "/discovered_users" =>                  "users#discovered_users",           as: "user_discovered_users"
    get "/stats" =>                             "users#stats",                      as: "user_stats"
  end

  # Twitter redirect
  get "/:screen_name/status(es)/:id" =>         redirect("/i/%{id}")
end

