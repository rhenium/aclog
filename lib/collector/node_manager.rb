module Collector
  module NodeManager
    @node_connections = []
    @active_connections = Array.new(Settings.collector.nodes_count)
    @inactive_connections = []

    class << self
      attr_reader :node_connections, :active_connections, :inactive_connections

      def register(node_connection)
        self.node_connections << node_connection
        self.inactive_connections << node_connection
        bind
      end

      def unregister(node_connection)
        self.node_connections.delete(node_connection)
        if i = self.active_connections.find_index(node_connection)
          self.active_connections[i] = nil
        else
          self.inactive_connections.delete(node_connection)
        end
        bind
      end

      def register_account(account)
        if con = self.active_connections[account.worker_number]
          con.register_account(account)
        end
      end

      def unregister_account(account)
        if con = self.active_connections[account.worker_number]
          con.unregister_account(account)
        end
      end

      private
      def bind
        if first_inactive_id = self.active_connections.find_index(nil)
          if con = self.inactive_connections.shift
            self.active_connections[first_inactive_id] = con
            con.activated_time = Time.now
            Rails.logger.warn("NodeManager") { "Registered node ##{con.connection_id} as group ##{first_inactive_id}" }
            Account.for_node(first_inactive_id).each do |a|
              con.register_account(a)
            end
          else
            Rails.logger.warn("NodeManager") { "Not enough nodes: (#{self.active_connections.count {|c| c }}/#{Settings.collector.nodes_count})" }
          end
        end
      end
    end
  end
end
