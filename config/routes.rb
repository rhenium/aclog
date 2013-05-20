Aclog::Application.routes.draw do
  root to: "about#index"

  # JSON
  scope "api", format: "json" do
    get "/users/:action", controller: "users"
    get "/tweets/:action", controller: "tweets"
  end

  # HTML only pages
  scope format: "html" do
    get "/search" => "search#search", as: "search"

    # Internals / SessionsController
    get "/i/import/:id" =>  "i#import",         as: "import"
    get "/i/callback" =>    "sessions#callback"
    get "/i/logout" =>      "sessions#destroy", as: "logout"

    # ReportController
    get "/i/report" => "report#index",          as: "report"

    get "/i/:id" =>         "tweets#show",      as: "tweet", constraints: {id: /\d+/}

    scope "about", controller: "about" do
      get "/",              action: "about",    as: "about"
      get "/api",           action: "api",      as: "about_api"
    end

    # User pages
    scope ":screen_name", controller: "users" do
      get "/stats",                         action: "stats",            as: "user_stats"
      get "/discovered_by",                 action: "discovered_by",    as: "user_discovered_by"
      get "/discovered_users",              action: "discovered_users", as: "user_discovered_users"
    end

    # Twitter redirect
    get "/:screen_name/status(es)/:id" => redirect("/i/%{id}")
  end

  # HTML or RSS
  scope controller: "tweets", constraints: {format: /(html|rss)/} do
    scope "i" do
      get "/best",      action: "all_best",     as: "best"
      get "/recent",    action: "all_recent",   as: "recent"
      get "/timeline",  action: "all_timeline", as: "timeline"
    end

    # TweetController / Tweets
    scope ":screen_name" do
      get "/",                              action: "best",          as: "user_best"
      get "/favorited",                     action: "favorited",     as: "user_favorited"
      get "/retweeted",                     action: "retweeted",     as: "user_retweeted"
      get "/recent",                        action: "recent",        as: "user_recent"
      get "/timeline",                      action: "timeline",      as: "user_timeline"
      get "/discoveries",                   action: "discoveries",   as: "user_discoveries"
      get "/favorites",                     action: "favorites",     as: "user_favorites"
      get "/retweets",                      action: "retweets",      as: "user_retweets"
      get "/discovered_by/:screen_name_b",  action: "discovered_by", as: "user_discovered_by_user"
    end
  end
end

