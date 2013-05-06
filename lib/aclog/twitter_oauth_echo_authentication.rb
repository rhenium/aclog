require "open-uri"

module Aclog
  module TwitterOauthEchoAuthentication
    extend self

    TWITTER_PROVIDER = "https://api.twitter.com/1.1/account/verify_credentials.json"

    module ControllerMethods
      extend ActiveSupport::Concern

      module ClassMethods
        def twitter_oauth_echo_authenticate_with(provider, options = {})
          before_action(options) do
            authenticate_with_twitter_oauth_echo
          end
        end
      end

      def authenticate_with_twitter_oauth_echo
        provider = request.headers["X-Auth-Service-Provider"]
        credentials = request.headers["X-Verify-Credentials-Authorization"]
        unless provider == TWITTER_PROVIDER && credentials
          raise Aclog::Exceptions::OAuthEchoUnauthorized
        end

        Aclog::TwitterOauthEchoAuthentication.authenticate(provider, credentials)
      end
    end

    def authenticate(provider, credentials)
      res = open(provider, "Authorization" => credentials)
      status = res.status[0].to_i
      json = JSON.parse(res.read)
      res.close

      json["id"]
    rescue => e
      raise Aclog::Exceptions::OAuthEchoUnauthorized
    end
  end
end

