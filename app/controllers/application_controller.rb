# -*- coding: utf-8 -*-
class ApplicationController < ActionController::Base
  include Aclog::TwitterOauthEchoAuthentication::ControllerMethods

  protect_from_forgery
  before_filter :check_format, :check_session
  after_filter :xhtml
  helper_method :authorized_to_show_user?, :authorized_to_show_best?

  protected
  def _get_user(id, screen_name)
    if id
      User.find(id) rescue raise Aclog::Exceptions::UserNotFound
    elsif screen_name
      User.find_by(screen_name: screen_name) or raise Aclog::Exceptions::UserNotFound
    end
  end

  def authorized_to_show_user?(user)
    @authorized_to_show_user ||= {}
    @authorized_to_show_user[user.id] ||= begin
      if !user.protected?
        true
      elsif session[:user_id] == user.id
        true
      elsif session[:account] && session[:account].following?(user.id)
        true
      elsif request.headers["X-Verify-Credentials-Authorization"]
        # OAuth Echo
        user_id = authenticate_with_twitter_oauth_echo
        account = Account.find_by(user_id: user_id)
        if account && (account.user_id == user.id || account.following?(user.id))
          true
        else
          false
        end
      else
        false
      end
    end
  end

  def authorized_to_show_best?(user)
    authorized_to_show_user?(user) && user.registered? && (!user.account.private? || user.id == session[:user_id])
  end

  def authorize_to_show_user!(user)
    authorized_to_show_user?(user) or raise Aclog::Exceptions::UserProtected
  end

  def authorize_to_show_best!(user)
    authorize_to_show_user!(user)
    raise Aclog::Exceptions::UserNotRegistered unless user.registered?
    raise Aclog::Exceptions::AccountPrivate if user.account.private? && user.id != session[:user_id]
    true
  end

  private
  def check_format
    unless request.format == :html || request.format == :json || request.format == :rss
      if params[:format] == nil
        request.format = :html
      else
        raise ActionController::RoutingError, "Not supported format: #{request.format}"
      end
    end
  end

  def check_session
    if (session[:user_id] || session[:account]) and not (session[:user_id] && session[:account])
      reset_session
    end
  end

  def xhtml
    if request.format == :html
      response.content_type = "application/xhtml+xml"

      # remove invalid charactors
      response.body = response.body.gsub(/[\x0-\x8\xb\xc\xe-\x1f]/, "")
    end
  end
end
