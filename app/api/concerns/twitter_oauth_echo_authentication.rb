require "open-uri"

module TwitterOauthEchoAuthentication
  def authenticate_with_twitter_oauth_echo
    twitter_provider = "https://api.twitter.com/1.1/account/verify_credentials.json"

    provider = headers["X-Auth-Service-Provider"]
    credentials = headers["X-Verify-Credentials-Authorization"]
    unless provider == twitter_provider && credentials
      raise Aclog::Exceptions::OAuthEchoError, "X-Auth-Service-Provider is invalid"
    end

    open(twitter_provider, "Authorization" => credentials) do |res|
      json = Oj.load(res.read)
      json["id"]
    end
  rescue OpenURI::HTTPError
    if $!.message.include?("401")
      raise Aclog::Exceptions::OAuthEchoUnauthorized, $!
    else
      raise $!
    end
  end
end
