# -*- coding: utf-8 -*-
class ApplicationController < ActionController::Base
  include Aclog::TwitterOauthEchoAuthentication::ControllerMethods

  protect_from_forgery
  before_filter :set_format, :check_session
  after_filter :xhtml

  protected
  def _get_user(id, screen_name)
    if id
      User.find(id) rescue raise Aclog::Exceptions::UserNotFound
    elsif screen_name
      User.find_by(screen_name: screen_name) || (raise Aclog::Exceptions::UserNotFound)
    end
  end

  def authorized_to_show?(user)
    return true if not user.protected?

    if session[:user_id]
      return session[:user_id] == user.id || session[:account].following?(user.id)
    elsif request.headers["X-Verify-Credentials-Authorization"]
      # OAuth Echo
      user_id = authenticate_with_twitter_oauth_echo
      account = Account.find_by(user_id: user_id)
      if account
        return account.user_id == user.id || account.following?(user.id)
      else
        return false
      end
    else
      return false
    end
  end

  private
  def set_format
    unless [:json, :html].include?(request.format.to_sym)
      request.format = :html
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
