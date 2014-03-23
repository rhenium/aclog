require "msgpack/rpc/transport/unix"

module Collector
  class Daemon
    def self.start
      _logger = Logger.new(STDOUT)
      _logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
      ActiveRecord::Base.logger = Rails.logger = _logger

      _sock_path = File.join(Rails.root, "tmp", "sockets", "receiver.sock")

      Rails.logger.info("Receiver started")
      File.delete(_sock_path) if File.exists?(_sock_path)
      EM.run do
        channel = EM::Channel.new
        EM.defer { channel.subscribe(&:call) }

        connections = {}

        collector_server = EM.start_server("0.0.0.0", Settings.collector.server_port, CollectorConnection, channel, connections)

        reg_svr_listener = MessagePack::RPC::UNIXServerTransport.new(_sock_path)
        register_server = MessagePack::RPC::Server.new
        register_server.listen(reg_svr_listener, RegisterServer.new(connections))
        EM.defer { register_server.run }

        stop = Proc.new do
          EM.stop_server(collector_server)
          register_server.close
          EM.stop
        end
        Signal.trap(:INT, &stop)
        Signal.trap(:TERM, &stop)
      end
    end
  end
end
