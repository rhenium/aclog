# -*- encoding: utf-8 -*-
class ErrorsController < ApplicationController
  skip_before_filter :check_format
  before_filter :force_format
  layout :select_layout

  def render_error
    @exception = env["action_dispatch.exception"]
    @title = "?"

    case @exception
    when OAuth::Unauthorized
      # /i/callback
      redirect_to root_path
    when Aclog::Exceptions::TweetNotFound
      @status = 404
      @message = t("error.tweet_not_found")
    when Aclog::Exceptions::UserNotFound
      @status = 404
      @message = t("error.user_not_found")
    when Aclog::Exceptions::LoginRequired
      @status = 403
      @message = t("error.login_required")
    when Aclog::Exceptions::OAuthEchoUnauthorized
      @status = 401
      @message = t("error.oauth_echo_unauthorized")
    when ActionController::RoutingError
      @status = 404
      @message = t("error.routing_error")
    when Aclog::Exceptions::UserNotRegistered
      @status = 404
      @message = t("error.user_not_registered")
    when Aclog::Exceptions::UserProtected
      @status = 403
      @message = t("error.user_protected")
    when Aclog::Exceptions::AccountPrivate
      @status = 403
      @message = t("error.account_private")
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
    if request.format == :html
      request.format = (env["REQUEST_PATH"].scan(/\.([A-Za-z]+)$/).flatten.first || :html).to_sym
    end

    unless request.format == :html || request.format == :json
      request.format = :html
    end
  end
end
