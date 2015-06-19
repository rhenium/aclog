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

    def permitted_to_see?(user_or_tweet)
      user_or_tweet.is_a?(User) ?
        !user_or_tweet.protected? ||      current_user.try(:permitted_to_see?, user_or_tweet) :
        !user_or_tweet.user.protected? || current_user.try(:permitted_to_see?, user_or_tweet.user)
    end
  end

  mount ApiTweets
  mount ApiUsers

  route :any, "*path", ignore: true do
    raise Aclog::Exceptions::NotFound
  end

  class << self
    def docs
      Rails.cache.fetch("apidocs") do
        {}.tap do |h|
          Api.routes.each {|route|
            next if route.route_ignore
            next if route.route_method == "HEAD"
            method = route.route_method
            namespace = route.route_namespace.sub(/^\//, "")
            path = route.route_path.split("/", 3).last.sub(/\(\.:format\)$/, "")
            ((h[method] ||= {})[namespace] ||= {})[path] = route
          }
        end
      end
    end
  end
end
