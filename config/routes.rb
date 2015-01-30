Rails.application.routes.draw do
  root "about#index"

  mount Api => "/api"

  get "/i/status" =>                            "about#status",                     as: "status"

  # Internals / SessionsController
  get "/i/callback" =>                          "sessions#create"
  get "/i/logout" =>                            "sessions#destroy",                 as: "logout"

  get "/i/:id" =>                               "tweets#show",                      as: "tweet", constraints: { id: /\d+/ }
  post "/i/:id/import" =>                       "tweets#import",                    as: "import", constraints: { id: /\d+/ }

  get "/i/settings" =>                          "settings#index",                   as: "settings"
  post "/i/settings/update" =>                  "settings#update"
  get "/i/settings/confirm_deactivation" =>     "settings#confirm_deactivation"
  post "/i/settings/deactivate" =>              "settings#deactivate"

  get "/i/best" =>                              "tweets#all_best",                  as: "best"
  get "/i/timeline" =>                          "tweets#all_timeline",              as: "timeline"
  get "/i/filter" =>                            "tweets#filter",                    as: "filter"

  get "/i/api/users/suggest_screen_name" =>     "users#i_suggest_screen_name"
  get "/i/api/tweets/responses" =>              "tweets#i_responses",               as: "tweet_responses"

  get "/about/api" =>                           "apidocs#index",                    as: "about_api"
  get "/about/api/:method/:namespace/:path" =>  "apidocs#endpoint",                 as: "about_api_endpoint", constraints: { namespace: /[\w\/]+/ }

  # User pages
  scope "/:screen_name" do
    get "/" =>                                  "tweets#user_index",                as: "user"
    get "/best" =>                              "tweets#user_best",                 as: "user_best"
    get "/timeline" =>                          "tweets#user_timeline",             as: "user_timeline"
    get "/favorites" =>                         "tweets#user_favorites",            as: "user_favorites"
    get "/favorited_by/:source_screen_name" =>  "tweets#user_favorited_by",         as: "user_favorited_by_user"

    get "/discovered_by" =>                     "users#discovered_by",              as: "user_discovered_by"
    get "/discovered_users" =>                  "users#discovered_users",           as: "user_discovered_users"
  end

  get "*unmatched_route" =>                     "application#routing_error"
end

