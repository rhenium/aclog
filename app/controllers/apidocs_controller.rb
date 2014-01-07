class ApidocsController < ApplicationController
  before_filter :reload_docs

  def index
    @resources = Apidoc.resources
  end

  def endpoint
    @resource = Apidoc.resources[params[:resource].to_sym]

    unless @resource
      raise Aclog::Exceptions::DocumentNotFound
    end

    @endpoint = @resource.endpoints[params[:name].to_sym]

    unless @endpoint
      raise Aclog::Exceptions::DocumentNotFound
    end
  end

  private
  def reload_docs
    Apidoc.reload_docs if Rails.env.development?
  end
end


