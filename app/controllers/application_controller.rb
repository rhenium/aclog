class ApplicationController < ActionController::Base
  include SecurityHeaders
  include ControllerErrorHandling
  include Utils

  protect_from_forgery with: :exception

  helper_method :logged_in?, :current_user
  helper_method :authorized?

  before_action :force_json

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

  def authorized?(object)
    case object
    when User
      !object.protected? ||
        logged_in? &&
        (object.id == current_user.id ||
         current_user.account.following?(object))
    when Tweet
      authorized?(object.user)
    else
      raise ArgumentError, "object must be User or Tweet"
    end
  end

  def authorize!(object)
    authorized?(object) ||
      raise(Aclog::Exceptions::UserProtected, object)

    object.is_a?(User) && object.opted_out? &&
      raise(Aclog::Exceptions::UserOptedOut, object)

    object
  end

  def force_json
    request.format = :json unless params[:format] == :atom
  end

  alias __render__ render

  def render(*args)
    raise ArgumentError, "don't use render, use render_json"
  end

  def render_json(data:, **kwargs)
    __render__({ json: { authenticity_token: form_authenticity_token, current_user: current_user, data: data } }.merge(kwargs))
  end
end
