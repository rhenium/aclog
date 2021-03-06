Bundler.require
require "yaml"
require "erb"
require "logger"
require "event_channel"
require "user_stream/client"
require "collector_connection"
require "user_connection"

Settings = OpenStruct.new(YAML.load(ERB.new(File.read(File.expand_path("../../settings.yml", __FILE__))).result))

class WorkerNode
  class << self
    def run
      EventChannel.setup
      Oj.default_options = { symbol_keys: true, mode: :strict }

      EM.epoll if Settings.epoll
      EM.set_descriptor_table_size(Settings.descriptor_table_size || 1024)
      EM.run do
        connection = EM.connect(Settings.collector_host, Settings.collector_port, CollectorConnection)

        stop = proc do
          Thread.new {
            logger.info "Exiting..."
            connection.exit
            EM.add_timer(0.1) { EM.stop }
          }.join
        end

        Signal.trap(:INT, &stop)
        Signal.trap(:TERM, &stop)
      end
    end

    def logger
      @logger ||= Logger.new(STDOUT).tap { |logger|
        logger.level = Settings.log_level.downcase.intern }
    end
  end
end
