require "msgpack/rpc/transport/unix"

class WorkerManager
  class << self
    def alive?
      !!client
    rescue Aclog::Exceptions::WorkerConnectionError
      false
    end

    def update_account(account)
      if account.active?
        client.call(:register_account, account.id)
      else
        client.call(:deactivate_account, account.id)
      end
    end

    def status
      client.call(:status)
    end

    private
    def client
      begin
        transport = MessagePack::RPC::UNIXTransport.new
        MessagePack::RPC::Client.new(transport, Rails.root.join("tmp", "sockets", "collector.sock").to_s)
      rescue Errno::ECONNREFUSED, Errno::ENOENT
        raise Aclog::Exceptions::WorkerConnectionError, "Couldn't connect to the background worker"
      end
    end
  end
end
