class SessionsController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]

    account = Account.create_or_update(user_id: auth["uid"],
                                       oauth_token: auth["credentials"]["token"],
                                       oauth_token_secret: auth["credentials"]["secret"],
                                       consumer_version: Settings.consumer_version)
    account.update_connection

    session[:account] = account
    session[:user_id] = account.user_id

    redirect_to root_path
  end

  def destroy
    reset_session

    redirect_to root_path
  end
end
