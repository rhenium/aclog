# -*- coding: utf-8 -*-
module Aclog
  module Receiver
    class RegisterServer
      def initialize(connections)
        @connections = connections
      end

      def register(account_)
        account = Marshal.load(account_)
        con_num = account.id % Settings.collector.count
        con = @connections[con_num]
        if con
          if account.active?
            con.send_account(account)
          else
            con.send_stop_account(account)
          end
        else
          Rails.logger.info("Connection not found: connection_number: #{con_num} / account_id: #{account.id}")
        end
      end
    end
  end
end

