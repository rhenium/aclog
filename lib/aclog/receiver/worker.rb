# -*- coding: utf-8 -*-
require "msgpack/rpc/transport/unix"

module Aclog
  module Receiver
    class Worker < DaemonSpawn::Base
      class RegisterServer
        def initialize(connections)
          @connections = connections
        end

        def register(account_)
          account = Marshal.load(account_)
          con_num = account.id % Settings.worker_count
          con = @connections[con_num]
          if con
            con.send_account(account)
            Rails.logger.info("Sent account: connection_number: #{con_num} / account_id: #{account.id}")
          else
            Rails.logger.info("Connection not found: connection_number: #{con_num} / account_id: #{account.id}")
          end
        end

        def unregister(account)
          # TODO
        end
      end

      def initialize(opts = {})
        super(opts) unless opts.empty?
        _logger = Logger.new(STDOUT)
        _logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
        ActiveRecord::Base.logger = Rails.logger = _logger
      end

      def start(args)
        Rails.logger.info("Receiver started")
        EM.run do
          connections = {}

          collector_server = EM.start_server("0.0.0.0", Settings.listen_port, Aclog::Receiver::CollectorServer, connections)

          reg_svr_listener = MessagePack::RPC::UNIXServerTransport.new(File.join(Rails.root, "tmp", "sockets", "receiver.sock"))
          register_server = MessagePack::RPC::Server.new
          register_server.listen(reg_svr_listener, RegisterServer.new(connections))
          EM.defer { register_server.run }

          stop = Proc.new do
            EM.stop_server(collector_server)
            register_server.close
            File.delete(File.join(Rails.root, "tmp", "sockets", "receiver.sock"))
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

