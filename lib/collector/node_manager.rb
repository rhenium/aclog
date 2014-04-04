module Collector
  class NodeManager
    @@node_connections = []
    @@active_connections = Array.new(Settings.collector.nodes_count)
    @@inactive_connections = []

    class << self
      def register(node_connection)
        @@node_connections << node_connection
        @@inactive_connections << node_connection
        bind
      end

      def unregister(node_connection)
        @@node_connections.delete(node_connection)
        i = @@active_connections.find_index(node_connection)
        if i
          @@active_connections[i] = nil
        else
          @@inactive_connections.delete(node_connection)
        end
        bind
      end

      def register_account(account)
        n = account.id % Settings.collector.nodes_count
        if @@active_connections[n]
          @@active_connections[n].register_account(account)
        end
      end

      def unregister_account(account)
        n = account.id % Settings.collector.nodes_count
        if @@active_connections[n]
          @@active_connections[n].unregister_account(account)
        end
      end

      private
      def bind
        first_inactive_id = @@active_connections.find_index(nil)
        if first_inactive_id
          con = @@inactive_connections.shift
          if con
            @@active_connections[first_inactive_id] = con
            Rails.logger.warn("[NodeManager] Registered node ##{con.connection_id} as group ##{first_inactive_id}")
            Account.for_node(first_inactive_id).each do |a|
              con.register_account(a)
            end
          else
            Rails.logger.warn("[NodeManager] Not enough nodes: (#{@@active_connections.count {|c| c }}/#{Settings.collector.nodes_count})")
          end
        end
      end

    end
  end
end
