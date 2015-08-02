if @worker_status
  json.nodes @worker_status["nodes"]
  json.active_nodes @worker_status["active_node_ids"]
  json.inactive_nodes @worker_status["inactive_node_ids"]
else
  json.error "The collector service is down."
end
