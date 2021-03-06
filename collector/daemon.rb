require "msgpack/rpc/transport/unix"
require_relative "event_queue"
require_relative "node_connection"
require_relative "node_manager"
require_relative "control_server"
require_relative "notification_queue"

module Collector
  module Daemon
    class << self
      attr_reader :start_time

      def start
        @start_time = Time.now
        set_loggers

        dalli = Dalli::Client.new(Settings.cache.memcached, namespace: "aclog-collector:")
        dalli.alive!

        EM.run do
          sock_path = File.join(Rails.root, "tmp", "sockets", "collector.sock")
          File.delete(sock_path) if File.exist?(sock_path)
          control = MessagePack::RPC::Server.new
          control.listen(MessagePack::RPC::UNIXServerTransport.new(sock_path), Collector::ControlServer.new)
          EM.defer { control.run }

          event_queue = EventQueue.start(dalli)
          NotificationQueue.start(dalli)

          nodes = EM.start_server("0.0.0.0", Settings.collector.server_port, Collector::NodeConnection, event_queue)

          stop = -> _ do
            control.stop
            EM.stop_server(nodes)
            EM.stop
          end

          Signal.trap("INT", &stop)
          Signal.trap("TERM", &stop)
        end
      end

      private
      def set_loggers
        _logger = Logger.new(STDOUT)
        _logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
        ActiveRecord::Base.logger = Rails.logger = _logger
      end
    end
  end
end
