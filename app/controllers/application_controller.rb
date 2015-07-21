class ApplicationController < ActionController::Base
  #include SecurityHeaders
  include ControllerErrorHandling
  include Utils

  protect_from_forgery with: :exception

  helper_method :logged_in?, :current_user
  helper_method :authorized_to_show_user?

  def routing_error
    raise ActionController::RoutingError, "No route matches #{params[:unmatched_route]}"
  end

  protected
  def logged_in?
    !!session[:user_id]
  end

  def current_user
    @_current_user ||=
      if logged_in?
        User.find(session[:user_id])
      end
  end

  def authorized_to_show_user?(user)
    !user.protected? ||
      (logged_in? && current_user.permitted_to_see?(user))
  end

  def authorize!(object)
    if object.is_a? User
      authorized_to_show_user?(object) || raise(Aclog::Exceptions::UserProtected, object)
    elsif object.is_a? Tweet
      authorize! object.user
    else
      raise ArgumentError, "parameter `object` must be a User or a Tweet"
    end
    object
  end

  def safe_redirect?(to)
    to[0] == "/" && !to.include?("//")
  end
end
