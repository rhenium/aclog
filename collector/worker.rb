# -*- coding: utf-8 -*-
require "logger"
require "./connection"

module Aclog
  module Collector
    class Worker
      def initialize
        @logger = Logger.new(STDOUT)
        @logger.level = Settings.env == "development" ? Logger::DEBUG : Logger::INFO
      end

      def start
        EM.run do
          connection = EM.connect(Settings.receiver_host, Settings.receiver_port, Aclog::Collector::Connection, @logger)

          stop = proc do
            @logger.info("Quitting collector...")
            connection.quit
            EM.stop
          end

          Signal.trap(:INT, &stop)
          Signal.trap(:TERM, &stop)
        end
      end
    end
  end
end
