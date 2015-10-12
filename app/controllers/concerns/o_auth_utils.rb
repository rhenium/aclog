require "oauth"

module OAuthUtils
  private
  def oauth_redirect(callback)
    request_token = consumer.get_request_token(oauth_callback: callback)
    session[:oauth] = { oauth_token: request_token.token,
                        oauth_token_secret: request_token.secret }

    redirect_to request_token.authorize_url
  end

  def oauth_verify!
    unless params[:oauth_verifier] && params[:oauth_token]
      raise Aclog::Exceptions::Unauthorized.new("OAuth related parameter missing")
    end

    unless session[:oauth] && session[:oauth][:oauth_token] == params[:oauth_token]
      raise Aclog::Exceptions::Unauthorized.new("Session expired or invalid")
    end

    request_token = ::OAuth::RequestToken.new(consumer, session[:oauth][:oauth_token], session[:oauth][:oauth_token_secret])
    request_token.get_access_token(oauth_verifier: params[:oauth_verifier])
  rescue OAuth::Unauthorized => e
    raise Aclog::Exceptions::Unauthorized, e
  end

  def consumer
    ::OAuth::Consumer.new(Settings.consumer.key,
                          Settings.consumer.secret,
                          site: "https://api.twitter.com",
                          authorize_path: "/oauth/authenticate")
  end
end
