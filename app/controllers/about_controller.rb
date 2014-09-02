class AboutController < ApplicationController
  def index
    render layout: "index"
  end

  def status
    @worker_status = WorkerManager.status
  rescue
  end
end
