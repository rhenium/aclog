module NodeManager
  class << self
    attr_reader :node_connections, :active_connections, :inactive_connections

    def setup
      @node_connections = []
      @active_connections = Array.new(Settings.nodes_count)
      @inactive_connections = []
      @accounts = Array.new(Settings.nodes_count) { {} }
    end

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
      id = account[:id]
      @accounts[id % Settings.nodes_count][id] = account

      if con = self.active_connections[id % Settings.nodes_count]
        con.register_account(account)
      end
    end

    def unregister_account(account)
      id = account[:id]
      @accounts[id % Settings.nodes_count].delete(id)

      if con = self.active_connections[id % Settings.nodes_count]
        con.unregister_account(account)
      end
    end

    def stats
      actives = @active_connections.map {|con|
        if con
          { activated_time: con.activated_time.to_i,
            connection_id: con.connection_id }
        else
          nil
        end
      }

      { active_node_statuses: actives }
    end

    private
    def bind
      if first_inactive_id = self.active_connections.find_index(nil)
        if con = self.inactive_connections.shift
          self.active_connections[first_inactive_id] = con
          con.activated_time = Time.now
          CollectorProxy.logger.info("NodeManager") { "Registered node ##{con.connection_id} as group ##{first_inactive_id}" }
          @accounts[first_inactive_id].values.each do |account|
            con.register_account(account)
          end
        else
          CollectorProxy.logger.warn("NodeManager") { "Not enough nodes: (#{self.active_connections.compact.size}/#{Settings.nodes_count})" }
        end
      end
    end
  end
end
