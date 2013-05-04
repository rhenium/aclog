Aclog::Application.routes.draw do
  constraints = {
    id: /[0-9]+/,
    user_id: /[0-9]+/,
    screen_name: /[a-zA-Z0-9_]{1,20}/,
    screen_name_b: /[a-zA-Z0-9_]{1,20}/,
    page: /[0-9]+/,
    count: /[0-9]+/,
    tweets: /(all|fav(orite[sd]?|(or)?ed|s)?|re?t(weet(s|ed)?|s)?)/,
    order: /(fav(orite[sd]?|(or)?ed|s)?|re?t(weet(s|ed)?|s)?)/,
  }

  # MainController
  root to: "main#index"

  get "/about" => "main#about", as: "about"
  get "/about/api" => "main#api", as: "about_api"

  get "/search" => "search#search", as: "search"

  # Internals / SessionsController
  get "/i/import/:id" => "i#import", constraints: constraints, as: "import"
  get "/i/callback" => "sessions#callback"
  get "/i/logout" => "sessions#destroy", as: "logout"

  # ReportController
  get "/i/report" => "report#index", as: "report"
  post "/i/report/tweet" => "report#tweet"

  # public
  get "/i/best" => "tweets#best", as: "best"
  get "/i/recent" => "tweets#recent", as: "recent"
  get "/i/timeline" => "tweets#timeline", as: "timeline"
  get "/i/:id" => "tweets#show", constraints: constraints, as: "tweet"
  get "(/users)/:screen_name/status(es)/:id" => redirect("/i/%{id}"), constraints: constraints

  # JSON API
  scope :api do
    get "/:controller/:action"
  end

  # deprecated API
  get "/users/best" => "tweets#best"
  get "/users/timeline" => "tweets#timeline"
  get "/users/discovered" => "tweets#discoveries"

  # Favstar redirects
  scope "users/:screen_name", constraints: constraints do
    get "/" =>                            redirect("/%{screen_name}")
    get "/most_favorited" =>              redirect("/%{screen_name}/favorited")
    get "/most_retweeted" =>              redirect("/%{screen_name}/retweeted")
    get "/discovered" =>                  redirect("/%{screen_name}/discoveries")
    get "/favorited" =>                   redirect("/%{screen_name}/favorites")
    get "/given" =>                       redirect("/%{screen_name}/favorites")
    get "/retweeted" =>                   redirect("/%{screen_name}/retweets")
    get "/recent" =>                      redirect("/%{screen_name}/timeline")
    get "/favs_from" =>                   redirect("/%{screen_name}/discovered_by")
    get "/retweeted_by" =>                redirect("/%{screen_name}/discovered_by")
    get "/favs_from/:screen_name_b" =>    redirect("/%{screen_name}/discovered_by/%{screen_name_b}")
    get "/retweeted_by/:screen_name_b" => redirect("/%{screen_name}/discovered_by/%{screen_name_b}")
    get "/given_to" =>                    redirect("/%{screen_name}/discovered_users")
    get "/given_to/:screen_name_b" =>     redirect("/%{screen_name_b}/discovered_by/%{screen_name}")
  end

  # User pages.
  scope ":screen_name", controller: "users", constraints: constraints do
    get "/stats",                        action: "stats",            as: "user_stats"
    get "/discovered_by",                action: "discovered_by",    as: "user_discovered_by"
    get "/discovered_users",             action: "discovered_users", as: "user_discovered_users"
  end
  scope ":screen_name", controller: "tweets", constraints: constraints do
    get "/(:page)",                      action: "best",          as: "user_best"
    get "/favorited(/:page)",            action: "favorited",     as: "user_favorited"
    get "/retweeted(/:page)",            action: "retweeted",     as: "user_retweeted"
    get "/recent(/:page)",               action: "recent",        as: "user_recent"
    get "/timeline",                     action: "timeline",      as: "user_timeline"
    get "/discoveries",                  action: "discoveries",   as: "user_discoveries"
    get "/favorites",                    action: "favorites",     as: "user_favorites"
    get "/retweets",                     action: "retweets",      as: "user_retweets"
    get "/discovered_by/:screen_name_b", action: "discovered_by", as: "user_discovered_by_user"
  end

  # Old URLs
  scope ":screen_name", constraints: constraints do
    get "/discovered" =>                        redirect("/%{screen_name}/discoveries")
    get "/info" =>                              redirect("/%{screen_name}/stats")
    get "/favorited_by" =>                      redirect("/%{screen_name}/discovered_by")
    get "/retweeted_by" =>                      redirect("/%{screen_name}/discovered_by")
    get "/favorited_by/:screen_name_b" =>       redirect("/%{screen_name}/discovered_by/%{screen_name_b}")
    get "/retweeted_by/:screen_name_b" =>       redirect("/%{screen_name}/discovered_by/%{screen_name_b}")
    get "/given_favorites_to" =>                redirect("/%{screen_name}/discovered_user")
    get "/given_retweets_to" =>                 redirect("/%{screen_name}/discovered_user")
    get "/given_favorites_to/:screen_name_b" => redirect("/%{screen_name_b}/discovered_by/%{screen_name}")
    get "/given_retweets_to/:screen_name_b" =>  redirect("/%{screen_name_b}/discovered_by/%{screen_name}")
  end

end
