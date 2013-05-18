Aclog::Application.routes.draw do
  constraints = {
    screen_name: /[a-zA-Z0-9_]{1,20}/,
    screen_name_b: /[a-zA-Z0-9_]{1,20}/,
  }

  root to: "main#index"

  scope format: false, constraints: constraints do
    get "/search" => "search#search", as: "search"

    # Internals / SessionsController
    get "/i/import/:id" =>  "i#import",         as: "import"
    get "/i/callback" =>    "sessions#callback"
    get "/i/logout" =>      "sessions#destroy", as: "logout"

    # ReportController
    get "/i/report" => "report#index",          as: "report"
    post "/i/report/tweet" => "report#tweet"

    scope "about", controller: "about" do
      get "/",              action: "about",    as: "about"
      get "/api",           action: "api",      as: "about_api"
    end

    # /i/
    scope :i, controller: :tweets do
      get "/best",      action: "all_best",     as: "best"
      get "/recent",    action: "all_recent",   as: "recent"
      get "/timeline",  action: "all_timeline", as: "timeline"
      get "/:id",       action: "show",         as: "tweet"
    end

    # JSON API
    scope "api", format: "json" do
      get "/:controller/:action"
    end

    # Favstar redirects
    get "(/users)/:screen_name/status(es)/:id" => redirect("/i/%{id}")
    scope "users/:screen_name" do
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
    scope ":screen_name", controller: "users" do
      get "/stats",                         action: "stats",            as: "user_stats"
      get "/discovered_by",                 action: "discovered_by",    as: "user_discovered_by"
      get "/discovered_users",              action: "discovered_users", as: "user_discovered_users"
    end

    scope ":screen_name", controller: "tweets" do
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

    # Old URLs
    scope ":screen_name" do
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
end

