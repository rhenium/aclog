module ApidocsHelper
  def format_endpoint_name(endpoint)
    endpoint.route_method + " " + endpoint.route_path.sub(/^\//, "").sub(/\(\.:format\)$/, "")
  end
end
