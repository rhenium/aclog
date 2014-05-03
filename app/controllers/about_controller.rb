class AboutController < ApplicationController
  def index
    render layout: "index"
  end

  def status
    @worker_status = WorkerManager.status

    if logged_in?
      @your_node_number = current_user.account.id % Settings.collector.nodes_count
    end
  rescue
  end
end
