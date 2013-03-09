Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter,
           Settings.consumer_key,
           Settings.consumer_secret,
           :request_path => "/i/login",
           :callback_path => "/i/callback"
end

