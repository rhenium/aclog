class ErrorsController < ApplicationController
  layout "index"

  def render_error
    @exception = env["action_dispatch.exception"]
    @status = ActionDispatch::ExceptionWrapper.new(env, @exception).status_code
    @title = "?"

    case @exception
    when OAuth::Unauthorized
      # /i/callback
      redirect_to root_path
    when Aclog::Exceptions::TweetNotFound
      render "error", status: 404
    when Aclog::Exceptions::UserNotFound
      render "error", status: 404
    when Aclog::Exceptions::UserNotRegistered
      render "error", status: 404
    when Aclog::Exceptions::UserProtected
      render "error", status: 403
    when Aclog::Exceptions::LoginRequired
      render "error", status: 403
    when Aclog::Exceptions::OAuthEchoUnauthorized
      render "error", status: 401
    when ActionController::RoutingError
      render "error", status: 404
    else
      render "error", status: 500
    end
  end
end
