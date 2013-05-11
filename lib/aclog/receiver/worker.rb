# -*- coding: utf-8 -*-
require "time"

module EM
  class Connection
    def send_object(data)
      send_data(data.to_msgpack)
    end
  end
end
module Aclog
  module Receiver
    class Worker < DaemonSpawn::Base
      class RegisterServer < EM::Connection
        def initialize
          @pac = MessagePack::Unpacker.new
        end

        def post_init
        end

        def receive_data(data)
          @pac.feed_each(data) do |msg|
            Rails.logger.debug(msg.to_s)
            unless msg["type"]
              Rails.logger.error("Unknown message")
              send_object({:type => "fatal", :message => "Unknown message"})
              close_connection_after_writing
              return
            end

            case msg["type"]
            when "register"
              account = Account.where(:id => msg["id"]).first
              if account
                Aclog::Receiver::CollectorServer.send_account(account)
                Rails.logger.info("Account registered and sent")
              else
                Rails.logger.error("Unknown account id")
                send_object({:type => "error", :message => "Unknown account id"})
              end
              close_connection_after_writing
            else
              Rails.logger.warn("Unknown register command: #{msg["type"]}")
            end
          end
        end
      end

      def initialize(opts = {})
        super(opts) unless opts.empty?
        _logger = Logger.new(STDOUT)
        _logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
        ActiveRecord::Base.logger = Rails.logger = _logger
      end

      def start(args)
        Rails.logger.info("Database Proxy Started")
        EM.run do
          o = EM.start_server("0.0.0.0", Settings.listen_port, Aclog::Receiver::CollectorServer)
          i = EM.start_unix_domain_server(File.join(Rails.root, "tmp", "sockets", "receiver.sock"), RegisterServer)

          stop = Proc.new do
            EM.stop_server(o)
            EM.stop_server(i)
            EM.stop
          end
          Signal.trap(:INT, &stop)
        end
      end

      def stop
      end
    end
  end
end

