module Collector
  module NodeManager
    @node_connections = []
    @active_connections = Array.new(Settings.collector.nodes_count)
    @inactive_connections = []

    class << self
      attr_reader :node_connections, :active_connections, :inactive_connections

      def register(con)
        node_connections << con
        inactive_connections << con
        bind
      end

      def unregister(con)
        node_connections.delete(con)
        if i = active_connections.find_index(con)
          active_connections[i] = nil
          bind
        else
          inactive_connections.delete(con)
        end
      end

      def register_account(account)
        if con = active_connections[account.worker_number]
          con.register_account(account)
        end
      end

      def unregister_account(account)
        if con = active_connections[account.worker_number]
          con.unregister_account(account)
        end
      end

      private
      def bind
        if first_inactive_id = active_connections.find_index(nil)
          if con = inactive_connections.shift
            con.activate(first_inactive_id)
            active_connections[first_inactive_id] = con
            Rails.logger.warn("NodeManager") { "Registered node ##{con.connection_id} as group ##{first_inactive_id}" }
          else
            Rails.logger.warn("NodeManager") { "Not enough nodes: (#{self.active_connections.count {|c| c }}/#{Settings.collector.nodes_count})" }
          end
        end
      end
    end
  end
end
