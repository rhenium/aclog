class AboutController < ApplicationController
  def index
  end

  def status
    @worker_status = WorkerManager.status
  rescue Aclog::Exceptions::WorkerConnectionError
  end
end
