require 'action_dispatch/middleware/session/dalli_store'
Aclog::Application.config.session_store ActionDispatch::Session::CacheStore, :expire_after => 3.days
