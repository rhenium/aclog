class ApidocsController < ApplicationController
  before_action :reload_docs

  def index
    @routes = @@routes
  end

  def endpoint
    @routes = @@routes

    method = @@routes[params[:method]]
    unless method
      raise Aclog::Exceptions::DocumentNotFound
    end

    @resource = method[params[:namespace]]
    unless @resource
      raise Aclog::Exceptions::DocumentNotFound
    end

    @endpoint = @resource[params[:path]]
    unless @endpoint
      raise Aclog::Exceptions::DocumentNotFound
    end

    if @endpoint.route_example_params
      @example_request_uri = api_url + @endpoint.route_path.sub(/\(\.:format\)$/, ".json")
      @example_request_uri += "?" + @endpoint.route_example_params.to_param
    end
  end

  private
  def reload_docs
    @@routes ||= begin
      h = {}
      Api.routes.reject {|r| r.route_ignore }.each {|route|
        # /tweets/show(.:format) -> tweets, show
        method = route.route_method.downcase
        namespace = route.route_namespace[1..-1]
        path = route.route_path.sub(route.route_namespace, "")[1..-11] # 10: "(.:format)".size
        ((h[method] ||= {})[namespace] ||= {})[path] = route
      }
      h
    end
  end
end


