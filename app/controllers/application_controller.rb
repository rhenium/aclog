# -*- coding: utf-8 -*-
class ApplicationController < ActionController::Base
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
    case
    when (not user.protected?)
      true
    when (not session[:user_id])
      false
    when user.id == session[:user_id]
      true
    when session[:account].following?(user)
      true
    else
      false
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
