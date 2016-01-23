require "grape/rabl"

class Api < Grape::API
  content_type :json, "application/json"
  default_format :json
  formatter :json, Grape::Formatter::Rabl
  error_formatter :json, ->(message, backtrace, options, env) do
    { error: { message: message } }.to_json
  end

  rescue_from ActiveRecord::RecordNotFound, Aclog::Exceptions::NotFound, rescue_subclasses: true do
    error_response message: "That page does not exists.", status: 404
  end
  rescue_from Aclog::Exceptions::Forbidden, rescue_subclasses: true do
    error_response message: "You do not have permission to access this page.", status: 403
  end
  rescue_from Aclog::Exceptions::OAuthEchoError, rescue_subclasses: true do
    error_response message: "Invalid OAuth Echo data.", status: 401
  end

  rescue_from :all

  helpers TwitterOauthEchoAuthentication

  helpers do
    def session
      env[Rack::Session::Abstract::ENV_SESSION_KEY]
    end

    def current_user
      @_current_user ||= begin
        if session.key?(:api_user_id)
          User.find(session[:api_user_id])
        elsif headers["X-Verify-Credentials-Authorization"]
          user_id = authenticate_with_twitter_oauth_echo
          session[:api_user_id] = user_id
          User.find(user_id)
        end
      end
    end

    def logged_in?
      !!current_user
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
  end

  mount ApiTweets
  mount ApiUsers

  route :any, "*path", nodoc: true do
    raise Aclog::Exceptions::NotFound
  end
end
