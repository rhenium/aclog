class ApplicationController < ActionController::Base
  include ControllerErrorHandling if Rails.env.production?

  protect_from_forgery with: :exception

  after_action :tidy_response_body
  helper_method :logged_in?, :current_user
  helper_method :authorized_to_show_user?, :authorized_to_show_user_best?

  def routing_error
    raise ActionController::RoutingError, "No route matches #{params[:unmatched_route]}"
  end

  protected
  def logged_in?
    !!session[:user_id]
  end

  def current_user
    @_current_user ||= begin
      if logged_in?
        User.find(session[:user_id])
      else
        nil
      end
    end
  end

  def authorized_to_show_user?(user)
    !user.protected? ||
      (logged_in? && current_user.permitted_to_see?(user))
  end

  def authorized_to_show_user_best?(user)
    user.registered? &&
      (!user.private? || current_user == user) &&
        authorized_to_show_user?(user)
  end

  def authorize_to_show_user!(user)
    authorized_to_show_user?(user) || raise(Aclog::Exceptions::UserProtected, user)
  end

  def authorize_to_show_user_best!(user)
    authorized_to_show_user_best?(user) || raise(Aclog::Exceptions::AccountPrivate, user)
  end

  private
  def tidy_response_body
    if [:html, :xml, :rss, :atom].any? {|s| request.format == s }
      response.body = ActiveSupport::Multibyte::Unicode.tidy_bytes(response.body)
    end
  end
end
