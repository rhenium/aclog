module WorkerNode
  class Worker
    def run
      EM.run do
        connection = EM.connect(Settings.collector_host, Settings.collector_port, CollectorConnection)

        stop = proc do
          puts "Stopping all connections...."
          connection.exit
          EM.add_timer(0.1) do
            EM.stop
          end
        end

        Signal.trap(:INT, &stop)
        Signal.trap(:TERM, &stop)
      end
    end
  end
end
