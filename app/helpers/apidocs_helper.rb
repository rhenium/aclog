module ApidocsHelper
  def format_endpoint_name(endpoint)
    endpoint.route_method + " " + endpoint.route_path[1..-11]
  end
end
