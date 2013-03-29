# Be sure to restart your server when you modify this file.

Aclog::Application.config.session_store ActionDispatch::Session::CacheStore, :expire_after => 3.days
