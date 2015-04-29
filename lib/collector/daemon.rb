require "msgpack/rpc/transport/unix"

module Collector
  module Daemon
    class << self
      attr_reader :start_time

      def start
        @start_time = Time.now
        set_loggers

        EM.run do
          sock_path = File.join(Rails.root, "tmp", "sockets", "collector.sock")
          File.delete(sock_path) if File.exists?(sock_path)
          control = MessagePack::RPC::Server.new
          control.listen(MessagePack::RPC::UNIXServerTransport.new(sock_path), Collector::ControlServer.new)
          EM.defer { control.run }

          event_queue = Collector::EventQueue.new
          EM.add_periodic_timer(Settings.collector.flush_interval) do
            event_queue.flush
          end

          proxy_connection = EM.connect(Settings.collector.proxy_host, Settings.collector.proxy_port, Collector::CollectorProxyConnection, event_queue)

          stop = proc do
            control.stop
            proxy_connection.exit
            
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
