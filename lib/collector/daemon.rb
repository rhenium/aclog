require "msgpack/rpc/transport/unix"

module Collector
  class Daemon
    class << self
      def start
        set_loggers

        EM.run do
          sock_path = File.join(Rails.root, "tmp", "sockets", "receiver.sock")
          File.delete(sock_path) if File.exists?(sock_path)
          control = MessagePack::RPC::Server.new
          control.listen(MessagePack::RPC::UNIXServerTransport.new(sock_path), Collector::ControlServer.new)
          EM.defer { control.run }

          nodes = EM.start_server("0.0.0.0", Settings.collector.server_port, Collector::NodeConnection)

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
