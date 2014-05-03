Rails.application.routes.draw do
  root "about#index"

  mount Api => "/api"

  get "/i/status" =>                            "about#status",                     as: "status"

  # Internals / SessionsController
  get "/i/callback" =>                          "sessions#create"
  get "/i/logout" =>                            "sessions#destroy",                 as: "logout"

  get "/i/user_jump_suggest" =>                 "users#user_jump_suggest",          as: "user_jump_suggest"

  get "/i/:id" =>                               "tweets#show",                      as: "tweet", constraints: { id: /\d+/ }
  get "/i/:id/import" =>                        "tweets#import",                    as: "import", constraints: { id: /\d+/ }

  get "/i/settings" =>                          "settings#index",                   as: "settings"
  post "/i/settings/update" =>                  "settings#update"
  get "/i/settings/confirm_deactivation" =>     "settings#confirm_deactivation"
  post "/i/settings/deactivate" =>              "settings#deactivate"

  get "/i/best" =>                              "tweets#all_best",                  as: "best"
  get "/i/recent" =>                            "tweets#all_recent",                as: "recent"
  get "/i/timeline" =>                          "tweets#all_timeline",              as: "timeline"
  get "/i/filter" =>                            "tweets#filter",                    as: "filter"

  get "/about/api" =>                           "apidocs#index",                    as: "about_api"
  get "/about/api/:method/:namespace/:path" =>  "apidocs#endpoint",                 as: "about_api_endpoint", constraints: { namespace: /[\w\/]+/ }

  # User pages
  scope "/:screen_name" do
    get "/" =>                                  "tweets#user_index",                as: "user"
    get "/best" =>                              "tweets#user_best",                 as: "user_best"
    get "/recent" =>                            "tweets#user_recent",               as: "user_recent"
    get "/timeline" =>                          "tweets#user_timeline",             as: "user_timeline"
    get "/discoveries" =>                       "tweets#user_discoveries",          as: "user_discoveries"
    get "/favorites" =>                         "tweets#user_favorites",            as: "user_favorites"
    get "/retweets" =>                          "tweets#user_retweets",             as: "user_retweets"
    get "/discovered_by/:source_screen_name" => "tweets#user_discovered_by",        as: "user_discovered_by_user"

    get "/discovered_by" =>                     "users#discovered_by",              as: "user_discovered_by"
    get "/discovered_users" =>                  "users#discovered_users",           as: "user_discovered_users"
    get "/stats" =>                             "users#stats",                      as: "user_stats"
  end

  # Twitter redirect
  get "/:screen_name/status(es)/:id" =>         redirect("/i/%{id}")

  get "*unmatched_route" =>                       "application#routing_error"
end

