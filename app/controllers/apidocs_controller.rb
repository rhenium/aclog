class ApidocsController < ApplicationController
  before_action :set_apidocs, :set_sidebar

  def index
  end

  def endpoint
    method = @apidocs[params[:method].to_s.upcase] || raise(Aclog::Exceptions::DocumentNotFound)
    @resource = method[params[:namespace]] || raise(Aclog::Exceptions::DocumentNotFound)
    @endpoint = @resource[params[:path]] || raise(Aclog::Exceptions::DocumentNotFound)
  end

  private
  def set_apidocs
    @apidocs = Rails.cache.fetch("apidocs", expired_in: 1.days) do
      h = {}
      Api.routes.reject {|r| r.route_ignore }.each {|route|
        next if route.route_method == "HEAD"
        method = route.route_method
        namespace = route.route_namespace.sub(/^\//, "")
        path = route.route_path.split("/", 3).last.sub(/\(\.:format\)$/, "")
        ((h[method] ||= {})[namespace] ||= {})[path] = route
      }
      h
    end
  end

  def set_sidebar
    @sidebars = [:apidocs]
  end
end
