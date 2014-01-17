class ApplicationController < ActionController::Base
  include Aclog::TwitterOauthEchoAuthentication::ControllerMethods

  protect_from_forgery
  after_action :set_content_type_to_xhtml, :tidy_response_body
  helper_method :current_user, :logged_in?
  helper_method :authorized_to_show_user?, :authorized_to_show_user_best?

  protected
  def current_user
    if session[:user_id]
      User.find(session[:user_id])
    elsif request.headers["X-Verify-Credentials-Authorization"]
      user_id = authenticate_with_twitter_oauth_echo
      User.find(user_id)
    end
  rescue
    nil
  end

  def logged_in?
    !!current_user
  end

  def authorized_to_show_user?(user)
    !user.protected? || current_user == user || current_user.try(:following?, user) || false
  end

  def authorized_to_show_user_best?(user)
    !user.private? || current_user == user
  end

  def authorize_to_show_user!(user)
    authorized_to_show_user?(user) || raise(Aclog::Exceptions::UserProtected, user)
  end

  def authorize_to_show_user_best!(user)
    authorized_to_show_user_best?(user) || raise(Aclog::Exceptions::AccountPrivate, user)
  end

  private
  def set_content_type_to_xhtml
    if request.format == :html
      response.content_type = "application/xhtml+xml"
    end
  end

  def tidy_response_body
    if [:html, :xml, :rss, :atom].any? {|s| request.format == s }
      response.body = ActiveSupport::Multibyte::Unicode.tidy_bytes(response.body)
    end
  end
end
