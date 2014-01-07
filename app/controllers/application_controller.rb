class ApplicationController < ActionController::Base
  include Aclog::TwitterOauthEchoAuthentication::ControllerMethods

  protect_from_forgery
  before_filter :check_format, :check_session
  after_filter :xhtml
  helper_method :current_user, :logged_in?, :allowed_to_see_user?, :allowed_to_see_best?

  protected
  def current_user
    if session[:user_id]
      User.find(session[:user_id])
    elsif request.headers["X-Verify-Credentials-Authorization"]
      user_id = authenticate_with_twitter_oauth_echo
      a = Account.find_by(user_id: user_id)
      a.user
    end
  rescue
    nil
  end

  def logged_in?
    !!current_user
  end

  def allowed_to_see_user?(user)
    !user.protected? ||
      logged_in? && (current_user == user || current_user.following?(user))
  end

  def allowed_to_see_best?(user)
    !user.private? || current_user == user
  end

  def require_user(user_id: params[:user_id], screen_name: params[:screen_name], public: false)
    begin
      user = User.find(id: user_id, screen_name: screen_name)
    rescue ActiveRecord::RecordNotFound
      raise Aclog::Exceptions::UserNotFound
    end

    if !allowed_to_see_user?(user)
      raise Aclog::Exceptions::UserProtected, user
    end

    if public && !allowed_to_see_best?(user)
      raise Aclog::Exceptions::AccountPrivate, user
    end

    user
  end

  private
  def check_format
    unless request.format == :html || request.format == :json || request.format == :rss || request.format == :atom
      if params[:format] == nil
        request.format = :html
      else
        raise ActionController::RoutingError, "Not supported format: #{request.format}"
      end
    end
  end

  def check_session
    if !!session[:user_id] == !!session[:account]
      true
    else
      reset_session
      false
    end
  end

  def xhtml
    if request.format == :html
      response.content_type = "application/xhtml+xml"
    end
    if request.format == :html || request.format == :rss
      # remove invalid charactors
      u = ActiveSupport::Multibyte::Unicode
      response.body = u.tidy_bytes(response.body)
    end
  end
end
