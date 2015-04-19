require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
# require "active_job/railtie"
# require "rails/test_unit/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Aclog
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Configure grape
    config.paths.add "app/api", eager_load: true
    config.paths.add "app/api/concerns", eager_load: true

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += Dir["#{config.root}/lib/", "#{config.root}/lib/**/"]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja
    config.i18n.fallbacks = true

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl
    end

    config.middleware.use(Rack::Config) do |env|
      env["api.tilt.root"] = "#{config.root}/app/api/templates"
    end

    console do
      require "console/helper"
      Rails::ConsoleMethods.include Console::Helper
      TOPLEVEL_BINDING.eval("self").extend Rails::ConsoleMethods
    end
  end
end
