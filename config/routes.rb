Rails.application.routes.draw do
  mount Api => "/api"

  root "about#index"
  get "/:screen_name/timeline.atom" => "tweets#user_timeline", defaults: { format: :atom } # Atom feed
  match "/i/api/:controller/:action", via: [:get, :post]
  get "*unmatched_route" =>                     "application#routing_error"
end

