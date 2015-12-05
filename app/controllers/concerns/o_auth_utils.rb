module OAuthUtils
  def oauth_redirect
    raise ArgumentError.new("oauth_callback is missing") unless params[:oauth_callback]
    request_token = consumer.get_request_token(oauth_callback: params[:oauth_callback])
    session[:oauth] = { oauth_token: request_token.token,
                        oauth_token_secret: request_token.secret }

    request_token.authorize_url
  end

  def oauth_callback
    raise ArgumentError.new("oauth_verifier is missing") unless params[:oauth_verifier]
    request_token = ::OAuth::RequestToken.new(consumer, session[:oauth][:oauth_token], session[:oauth][:oauth_token_secret])
    access_token = request_token.get_access_token(oauth_verifier: params[:oauth_verifier])
    account = Account.register(user_id: access_token.params[:user_id],
                                oauth_token: access_token.token,
                                oauth_token_secret: access_token.secret)
    User.update_from_twitter(account.user_id, account) rescue nil
    session.delete(:oauth)
    session[:user_id] = account.user_id

    account
  rescue OAuth::Unauthorized => e
    raise Aclog::Exceptions::Unauthorized, e
  end

  private
  def consumer
    ::OAuth::Consumer.new(Settings.consumer.key,
                          Settings.consumer.secret,
                          site: "https://api.twitter.com",
                          authorize_path: "/oauth/authenticate")
  end
end
