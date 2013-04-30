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

  # Internals / SessionsController
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

  # User pages.
  scope ":screen_name", controller: "users", constraints: constraints do
    get "/info",                         action: "info",            as: "user_info"
    get "/discovered_by",                action: "discovered_by",   as: "user_discovered_by"
    get "/discovered_of",                action: "discovered_of",   as: "user_discovered_of"
  end
  scope ":screen_name", controller: "tweets", constraints: constraints do
    get "/(:page)",                      action: "best",          as: "user_best"
    get "/favorited(/:page)",            action: "favorited",     as: "user_favorited"
    get "/retweeted(/:page)",            action: "retweeted",     as: "user_retweeted"
    get "/recent(/:page)",               action: "recent",        as: "user_recent"
    get "/timeline",                     action: "timeline",      as: "user_timeline"
    get "/discoveries",                  action: "discoveries",   as: "user_discoveries"
    get "/discovered_by/:screen_name_b", action: "discovered_by", as: "user_discovered_by_user"
  end


  # Favstar redirects
  scope "users/:screen_name", constraints: constraints do
    get "/" => redirect("/%{screen_name}")
    get "/most_favorited" => redirect("/%{screen_name}/favorite")
    get "/most_retweeted" => redirect("/%{screen_name}/retweet")
    get "/discovered" => redirect("/%{screen_name}/discovered")
    get "/favorited" => redirect("/%{screen_name}/discovered/favorite")
    get "/given" => redirect("/%{screen_name}/discovered/favorite")
    get "/retweeted" => redirect("/%{screen_name}/discovered/retweet")
    get "/recent" => redirect("/%{screen_name}/timeline")
    get "/favs_from" => redirect("/%{screen_name}/favorited_by")
    get "/favs_from/:screen_name_b" => redirect("/%{screen_name}/favorited_by/%{screen_name_b}")
    get "/retweeted_by" => redirect("/%{screen_name}/retweeted_by")
    get "/retweeted_by/:screen_name_b" => redirect("/%{screen_name}/retweeted_by/%{screen_name_b}")
    get "/given_to" => redirect("/%{screen_name}/given_favorites_to")
    get "/given_to/:screen_name_b" => redirect("/%{screen_name}/given_favorites_to/%{screen_name_b}")
  end

  # deprecated API
  get "/users/best" => "tweets#best"
  get "/users/recent" => "tweets#recent"
  get "/users/timeline" => "tweets#timeline"
  get "/users/discovered" => "tweets#discoveries"
end
