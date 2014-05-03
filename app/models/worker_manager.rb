require "msgpack/rpc/transport/unix"
class WorkerManager
  class << self
    def alive?
      client && true rescue false
    end

    def update_account(account)
      if account.active?
        client.call(:register_account, Marshal.dump(account))
      else
        client.call(:deactivate_account, Marshal.dump(account))
      end
    end

    def status
      Marshal.load(client.call(:status))
    end

    private
    def client
      @client ||= begin
        transport = MessagePack::RPC::UNIXTransport.new
        MessagePack::RPC::Client.new(transport, Rails.root.join("tmp", "sockets", "collector.sock").to_s)
      rescue Errno::ECONNREFUSED, Errno::ENOENT
        raise Aclog::Exceptions::WorkerConnectionError, "Couldn't connect to the background worker"
      end
    end
  end
end
