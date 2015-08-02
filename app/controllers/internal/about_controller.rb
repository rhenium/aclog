class Internal::AboutController < Internal::ApplicationController
  def status
    @worker_status = WorkerManager.status
  rescue Aclog::Exceptions::WorkerConnectionError
  end
end
