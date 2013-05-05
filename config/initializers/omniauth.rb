OmniAuth.config.full_host = -> env do
  scheme = env["rack.url_scheme"]
  forwarded_host = env["HTTP_X_FORWARDED_HOST"]

  host = forwarded_host.blank? ?
    env["HTTP_HOST"] :
    forwarded_host

  "#{scheme}://#{host}"
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter,
           Settings.collector.consumer[Settings.collector.consumer_version].key,
           Settings.collector.consumer[Settings.collector.consumer_version].secret,
           request_path: "/i/login",
           callback_path: "/i/callback"
end

