module Collector
  class ControlServer
    def register_account(account_id)
      CollectorProxyConnection.instance.register_account(Account.find(account_id))
    end

    def deactivate_account(account_id)
      CollectorProxyConnection.instance.unregister_account(Account.find(account_id))
    end

    def status
      con = CollectorProxyConnection.instance
      if con.connected
        con.last_stats
      else
        nil
      end
    end
  end
end
