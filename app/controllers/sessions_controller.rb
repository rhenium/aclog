class SessionsController < ApplicationController
  include OAuthUtils

  def new
    return redirect_to root_path if logged_in?

    session[:redirect_after_login] = params[:redirect_after_login]
    oauth_redirect(sessions_create_url)
  end

  def create
    return redirect_to root_path if logged_in?

    access_token = oauth_verify!

    account = Account.register(user_id: access_token.params[:user_id],
                               oauth_token: access_token.token,
                               oauth_token_secret: access_token.secret)
    User.update_from_twitter(account.user_id, account) rescue nil

    begin
      WorkerManager.update_account(account)
    rescue Aclog::Exceptions::WorkerConnectionError
    end

    session[:user_id] = account.user_id

    if safe_redirect?(session[:redirect_after_login])
      redirect_to session[:redirect_after_login]
    else
      redirect_to user_path(account.user.screen_name)
    end
  end

  def destroy
    reset_session

    redirect_to root_path
  end
end
