module Collector
  class ControlServer
    def register_account(account_id)
      NodeManager.register_account(Account.find(account_id))
    end

    def deactivate_account(account_id)
      NodeManager.unregister_account(Account.find(account_id))
    end

    def status
      active_node_statuses = Settings.collector.nodes_count.times.map do |number|
        node = NodeManager.active_connections[number]
        if node
          { activated_time: node.activated_time.to_i,
            connection_id: node.connection_id }
        else
          nil
        end
      end

      { start_time: Daemon.start_time.to_i,
        active_node_statuses: active_node_statuses,
        inactive_nodes_count: NodeManager.inactive_connections.size }
    end
  end
end
