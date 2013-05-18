# -*- encoding: utf-8 -*-
class ErrorsController < ApplicationController
  layout "index"
  skip_before_filter :check_format
  before_filter :force_format

  def render_error
    @exception = env["action_dispatch.exception"]
    @status = ActionDispatch::ExceptionWrapper.new(env, @exception).status_code
    @title = "?"

    case @exception
    when OAuth::Unauthorized
      # /i/callback
      redirect_to root_path
    when Aclog::Exceptions::TweetNotFound
      @message = "ツイートが見つかりませんでした。"
      render "error", status: 404
    when Aclog::Exceptions::UserNotFound
      @message = "ユーザーが見つかりませんでした。"
      render "error", status: 404
    when Aclog::Exceptions::UserNotRegistered
      @message = "ユーザーは aclog に登録していません。"
      render "error", status: 404
    when Aclog::Exceptions::UserProtected
      @message = "ユーザーは非公開です。"
      render "error", status: 403
    when Aclog::Exceptions::LoginRequired
      @message = "このページの表示にはログインが必要です。"
      render "error", status: 403
    when Aclog::Exceptions::OAuthEchoUnauthorized
      @message = "OAuth Echo 認証に失敗しました。"
      render "error", status: 401
    when ActionController::RoutingError
      @message = "このページは存在しません。"
      render "error", status: 404
    else
      @message = "Internal Error: #{@exception.class}"
      render "error", status: 500
    end
  end

  private
  def force_format
    unless [:json, :html].include?(request.format.to_sym)
      request.format = "html"
    end
  end
end
