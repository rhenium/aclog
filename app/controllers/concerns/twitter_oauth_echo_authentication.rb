require "open-uri"

module TwitterOauthEchoAuthentication
  def authenticate_with_twitter_oauth_echo
    twitter_provider = "https://api.twitter.com/1.1/account/verify_credentials.json"

    provider = request.headers["X-Auth-Service-Provider"]
    credentials = request.headers["X-Verify-Credentials-Authorization"]
    unless provider == twitter_provider && credentials
      raise Aclog::Exceptions::OAuthEchoUnauthorized, "X-Auth-Service-Provider is invalid"
    end

    json = open(twitter_provider, "Authorization" => credentials) {|res|
      Yajl::Parser.parse(res.read)
    }

    json["id"]
  rescue
    raise Aclog::Exceptions::OAuthEchoUnauthorized, $!
  end
end

