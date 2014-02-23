class Api < Grape::API
  format :json
  formatter :json, Grape::Formatter::Rabl
  error_formatter :json, ->(message, backtrace, options, env) do
    { error: { message: message } }.to_json
  end

  rescue_from ActiveRecord::RecordNotFound, Aclog::Exceptions::NotFound do
    error_response message: "That page does not exists.", status: 404
  end
  rescue_from Aclog::Exceptions::Forbidden do
    error_response message: "You do not have permission to access this page.", status: 403
  end
  rescue_from Aclog::Exceptions::OAuthEchoError do
    error_response message: "Invalid OAuth Echo data.", status: 401
  end

  rescue_from :all

  helpers TwitterOauthEchoAuthentication

  helpers do
    def current_user
      @_current_user ||= begin
        if headers["X-Verify-Credentials-Authorization"]
          user_id = authenticate_with_twitter_oauth_echo
          User.find(user_id)
        end
      end
    rescue Aclog::Exceptions::OAuthEchoUnauthorized
      raise Aclog::Exceptions::OAuthEchoError, $!
    end

    def permitted_to_see?(user_or_tweet)
      user_or_tweet.is_a?(User) ?
        !user_or_tweet.protected? ||      current_user.try(:permitted_to_see?, user_or_tweet) :
        !user_or_tweet.user.protected? || current_user.try(:permitted_to_see?, user_or_tweet.user)
    end
  end

  mount ApiTweets
  mount ApiUsers
  mount ApiDeprecated

  route :any, "*path", ignore: true do
    raise Aclog::Exceptions::NotFound
  end
end
