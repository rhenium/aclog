source "https://rubygems.org"

gem "rails", "~> 4.0.2"
gem "mysql2"
gem "settingslogic"
gem "yajl-ruby", require: "yajl"
gem "twitter"
gem "twitter-text"
gem "omniauth-twitter"
gem "haml-rails"
gem "jbuilder"
gem "sass-rails"
gem "coffee-rails"
gem "uglifier"
gem "jquery-rails"
gem "bootstrap-sass-rails"
gem "daemon-spawn", require: "daemon_spawn"
gem "msgpack"
gem "msgpack-rpc"
gem "em-work_queue"
gem "pry-rails"

group :production do
  gem "unicorn"
  gem "unicorn-worker-killer"
  gem "dalli"
end

group :development do
  gem "thin"
end

group :test do
  gem "rspec"
  gem "rspec-rails"
  gem "factory_girl_rails"
  gem "webmock"
  gem "coveralls", require: false
  gem "simplecov", require: false
end

