Rails.application.routes.draw do
  mount Api => "/api"

  root "about#index"
  get "/:screen_name/timeline" => "tweets#user_timeline" # Atom feed
  match "/i/api/:controller/:action", via: [:get, :post]
  get "*unmatched_route" => "application#action_missing"
end
