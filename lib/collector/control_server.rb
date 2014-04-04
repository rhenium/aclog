module Collector
  class ControlServer
    def register_account(account)
      NodeManager.register_account(Marshal.load(account))
    end

    def deactivate_account(account)
      NodeManager.unregister_account(Marshal.load(account))
    end
  end
end
