Bundler.require
require "yaml"
require "logger"
require "event_channel"
require "node_manager"
require "collector_connection"
require "worker_node_connection"

Settings = OpenStruct.new(YAML.load_file(File.expand_path("../../settings.yml", __FILE__)))

class CollectorProxy
  class << self
    def run
      EventChannel.setup
      NodeManager.setup

      EM.run do
        collector_connection = EM.start_server("0.0.0.0", Settings.collector_port, CollectorConnection)
        worker_node_connections = EM.start_server("0.0.0.0", Settings.worker_node_port, WorkerNodeConnection)

        stop = proc do
          EM.stop_server(worker_node_connections)
          sleep 1
          EM.stop_server(collector_connection)
          EM.stop
        end

        Signal.trap(:INT, &stop)
        Signal.trap(:TERM, &stop)
      end
    end

    def logger
      @logger ||= Logger.new(STDOUT).tap {|l|
        l.level = Logger.const_get(Settings.log_level.upcase) }
    end
  end
end
