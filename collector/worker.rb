require "./settings"
require "./connection"

module Aclog
  module Collector
    class Worker
      def initialize(logger)
        @logger = logger
      end

      def start
        EM.run do
          connection = EM.connect(Settings.receiver_host, Settings.receiver_port, Connection, @logger)

          stop = proc do
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
