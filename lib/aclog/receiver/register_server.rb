# -*- coding: utf-8 -*-
module Aclog
  module Receiver
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
  end
end

