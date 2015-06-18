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
    @apidocs = Api.docs
  end

  def set_sidebar
    @sidebars = [:apidocs]
  end
end
