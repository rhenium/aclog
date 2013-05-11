# -*- coding: utf-8 -*-
require "msgpack/rpc/transport/unix"

module Aclog
  module Receiver
    class Worker < DaemonSpawn::Base
      def initialize(opts = {})
        super(opts) unless opts.empty?
        _logger = Logger.new(STDOUT)
        _logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
        ActiveRecord::Base.logger = Rails.logger = _logger
      end

      def start(args)
        _sock_path = File.join(Rails.root, "tmp", "sockets", "receiver.sock")

        Rails.logger.info("Receiver started")
        File.delete(_sock_path) if File.exists?(_sock_path)
        EM.run do
          connections = {}

          collector_server = EM.start_server("0.0.0.0", Settings.listen_port, CollectorConnection, connections)

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

      def stop
      end
    end
  end
end

