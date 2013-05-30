# -*- encoding: utf-8 -*-
class ErrorsController < ApplicationController
  skip_before_filter :check_format
  before_filter :force_format
  layout :select_layout

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
    when Aclog::Exceptions::LoginRequired
      @status = 403
      @message = "このページの表示にはログインが必要です。"
    when Aclog::Exceptions::OAuthEchoUnauthorized
      @status = 401
      @message = "OAuth Echo 認証に失敗しました。"
    when ActionController::RoutingError
      @status = 404
      @message = "このページは存在しません。"
    when Aclog::Exceptions::UserNotRegistered
      @status = 404
      @message = "ユーザーは aclog に登録していません。"
    when Aclog::Exceptions::UserProtected
      @status = 403
      @message = "ユーザーは非公開です。"
    when Aclog::Exceptions::AccountPrivate
      @status = 403
      @message = "ユーザーの best は非公開です"
    else
      @status = 500
      @message = "Internal Error: #{@exception.class}"
    end

    if @exception.is_a? Aclog::Exceptions::UserError
      @user = @exception.user
    end

    respond_to do |format|
      format.html { render status: @status }
      format.json { render status: @status }
    end
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
