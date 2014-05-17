module Collector
  class ControlServer
    def register_account(account)
      NodeManager.register_account(Marshal.load(account))
    end

    def deactivate_account(account)
      NodeManager.unregister_account(Marshal.load(account))
    end

    def status
      active_node_statuses = Settings.collector.nodes_count.times.map do |number|
        node = NodeManager.active_connections[number]
        if node
          { activated_time: node.activated_time }
        else
          nil
        end
      end

      res = { start_time: Daemon.start_time,
              active_node_statuses: active_node_statuses,
              inactive_nodes_count: NodeManager.inactive_connections.size }
      Marshal.dump(res)
    end
  end
end
