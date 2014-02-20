class ErrorsController < ApplicationController
  before_action :force_format
  layout :select_layout

  def render_error
    @exception = env["action_dispatch.exception"]

    case @exception
    when OAuth::Unauthorized
      # only /i/callback: when Cancel pressed on Twitter's OAuth
      redirect_to root_path
    when Aclog::Exceptions::LoginRequired,
         Aclog::Exceptions::UserProtected,
         Aclog::Exceptions::AccountPrivate
      @status = 403
      @message = t("error.forbidden")
    when ActionController::RoutingError,
         ActiveRecord::RecordNotFound,
         ActionView::MissingTemplate,
         Aclog::Exceptions::UserNotRegistered
      @status = 404
      @message = t("error.not_found")
    else
      @status = 500
      @message = "#{t("error.internal_error")}: #{@exception.class}"
    end

    if @exception.is_a? Aclog::Exceptions::UserError
      @user = @exception.user
    end

    render status: @status
  end

  private
  def select_layout
    @user ? nil : "index"
  end

  def force_format
    request.format = (env["REQUEST_PATH"].scan(/\.([A-Za-z]+)$/).flatten.first || :html).to_sym

    unless request.format == :html || request.format == :json
      request.format = :html
    end
  end
end
