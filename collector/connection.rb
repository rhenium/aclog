# -*- coding: utf-8 -*-
require "msgpack"
require "./settings"
require "./stream"

module Aclog
  module Collector
    class Connection < EM::Connection
      def initialize(logger)
        @logger = logger
        @clients = {}
        @pac = MessagePack::Unpacker.new
        @connected = false
      end

      def post_init
        send_object(type: "init",
                    secret_key: Settings.secret_key)
      end

      def unbind
        @logger.info("Connection closed") if @connected
        EM.add_timer(10) do
          @connected = false
          reconnect(Settings.receiver_host, Settings.receiver_port)
          post_init
        end
      end

      # Server
      def receive_data(data)
        @pac.feed_each(data) do |msg|
          if not msg.is_a?(Hash) or not msg["type"]
            @logger.warn("Unknown data: #{msg}")
            close_connection_after_writing
            return
          end

          case msg["type"]
          when "ok"
            @connected = true
            @logger.info("Connected with server")
          when "error"
            @logger.info("error: #{msg["message"]}")
          when "fatal"
            @logger.info("fatal: #{msg["message"]}")
            close_connection
          when "bye"
            close_connection
          when "account"
            account_id = msg["id"]
            if not @clients[account_id]
              user_connection = Aclog::Collector::Stream.new(@logger, method(:send_object), msg)
              user_connection.start
              @clients[account_id] = user_connection
            else
              @clients[account_id].update(msg)
            end
          when "stop"
            account_id = msg["id"]
            if @clients[account_id]
              @clients[account_id].stop
              @clients.delete(account_id)
              @logger.info("Received account stop")
            end
          else
            @logger.info("Unknown message: #{msg}")
          end
        end
      end

      def quit
        send_object(type: "quit", reason: "stop")
        @clients.values.map(&:stop)
      end

      private
      def send_object(data)
        send_data(data.to_msgpack)
      end
    end
  end
end


