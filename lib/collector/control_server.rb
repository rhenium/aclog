module Collector
  class ControlServer
    def register_account(account_id)
      NodeManager.register_account(Account.find(account_id))
    end

    def deactivate_account(account_id)
      NodeManager.unregister_account(Account.find(account_id))
    end

    def status
      nodes = {}
      NodeManager.node_connections.each {|node|
        nodes[node.connection_id] = { activated_at: (a = node.activated_at) && a.to_i }
      }

      { started_at: Daemon.start_time.to_i,
        nodes: nodes,
        active_node_ids: NodeManager.active_connections.map {|n| n && n.connection_id },
        inactive_node_ids: NodeManager.inactive_connections.map {|n| n.connection_id } }
    end
  end
end
