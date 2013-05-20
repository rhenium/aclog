# -*- encoding: utf-8 -*-
class ErrorsController < ApplicationController
  layout "index"
  skip_before_filter :check_format
  before_filter :force_format

  def render_error
    @exception = env["action_dispatch.exception"]
    #@status = ActionDispatch::ExceptionWrapper.new(env, @exception).status_code
    @title = "?"

    case @exception
    when OAuth::Unauthorized
      # /i/callback
      redirect_to root_path
    when Aclog::Exceptions::TweetNotFound
      @status = 404
      @message = "ツイートが見つかりませんでした。"
    when Aclog::Exceptions::UserNotFound
      @status = 404
      @message = "ユーザーが見つかりませんでした。"
    when Aclog::Exceptions::UserNotRegistered
      @status = 404
      @message = "ユーザーは aclog に登録していません。"
    when Aclog::Exceptions::UserProtected
      @status = 403
      @message = "ユーザーは非公開です。"
    when Aclog::Exceptions::LoginRequired
      @status = 403
      @message = "このページの表示にはログインが必要です。"
    when Aclog::Exceptions::OAuthEchoUnauthorized
      @status = 401
      @message = "OAuth Echo 認証に失敗しました。"
    when ActionController::RoutingError
      @status = 404
      @message = "このページは存在しません。"
    else
      @status = 500
      @message = "Internal Error: #{@exception.class}"
    end

    render status: @status
  end

  private
  def force_format
    if request.format == :html
      request.format = env["REQUEST_PATH"].scan(/\.([A-Za-z]+)$/).flatten.first || :html
    end

    unless request.format == :html || request.format == :json
      request.format = :html
    end
  end
end
