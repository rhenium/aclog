require "settingslogic"

module Aclog
  module Collector
    class Settings < Settingslogic
      def self.env
        ENV["RAILS_ENV"] || "development"
      end

      source "settings.yml"
      namespace env
    end
  end
end

