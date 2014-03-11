class ErrorsController < ApplicationController
  before_action :force_format

  def render_error
    @exception = env["action_dispatch.exception"]

    case @exception
    when Aclog::Exceptions::Forbidden
      @status = 403
      @message = t("error.forbidden")
    when ActionController::RoutingError,
         ActiveRecord::RecordNotFound,
         ActionView::MissingTemplate,
         Aclog::Exceptions::NotFound
      @status = 404
      @message = t("error.not_found")
    when OAuth::Unauthorized,
         Aclog::Exceptions::Unauthorized
      @status = 401
      @message = ""
    else
      @status = 500
      @message = "#{t("error.internal_error")}: #{@exception.class}"
    end

    render status: @status
  end

  private
  def force_format
    request.format = (env["REQUEST_PATH"].scan(/\.([A-Za-z]+)$/).flatten.first || :html).to_sym

    unless request.format == :html || request.format == :json
      request.format = :html
    end
  end
end
