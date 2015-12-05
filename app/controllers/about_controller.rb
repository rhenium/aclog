class AboutController < ApplicationController
  def status
    worker_status = WorkerManager.status
    render_json success: {
      nodes: worker_status["nodes"],
      active_nodes: worker_status["active_node_ids"],
      inactive_nodes: worker_status["inactive_node_ids"]
    }
  end
end
