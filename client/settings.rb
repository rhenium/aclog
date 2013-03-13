require "settingslogic"

class Settings < Settingslogic
  source "settings.yml"
  namespace ENV["RAILS_ENV"]
end
