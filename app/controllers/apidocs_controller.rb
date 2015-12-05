class ApidocsController < ApplicationController
  def all
    apidocs = Rails.cache.fetch("apidocs/all") do
      nss = {}
      Api.routes.each { |route|
        next if route.route_ignore
        next if route.route_method == "HEAD"
        namespace = route.route_namespace.sub(/^\//, "")
        nss[namespace] ||= []
        nss[namespace] << { method: route.route_method,
                            description: route.route_description,
                            path: route.route_path.sub(/^\//, "").sub(/\(\.:format\)$/, ""),
                            params: route.route_params.map { |n, o| [n, { required: o[:required], description: o[:desc], type: o[:type] }] }.to_h,
                            example_params: route.route_example_params,
        }
      }
      nss
    end

    render_json data: { namespaces: apidocs }
  end
end
