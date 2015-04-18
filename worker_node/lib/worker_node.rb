Bundler.require
require "yaml"
require "logger"
require "event_channel"
require "user_stream/client"
require "collector_connection"
require "user_connection"

Settings = OpenStruct.new(YAML.load_file(File.expand_path("../../settings.yml", __FILE__)))

class WorkerNode
  class << self
    def run
      EventChannel.setup

      EM.run do
        connection = EM.connect(Settings.collector_host, Settings.collector_port, CollectorConnection)

        stop = proc do
          Thread.new {
            WorkerNode.logger.info "Exiting..."
            connection.exit
            EM.add_timer(0.1) { EM.stop }
          }.join
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
