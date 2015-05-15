class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]

    account = Account.register(user_id: auth.uid,
                               oauth_token: auth.credentials.token,
                               oauth_token_secret: auth.credentials.secret)
    begin
      WorkerManager.update_account(account)
    rescue Aclog::Exceptions::WorkerConnectionError
    end

    User.create_or_update_from_json(
      { id: account.user_id,
        screen_name: auth.extra.raw_info.screen_name,
        name: auth.extra.raw_info.name,
        profile_image_url_https: auth.extra.raw_info.profile_image_url_https,
        protected: auth.extra.raw_info.protected })

    session[:user_id] = account.user_id

    to = request.env["omniauth.params"]["redirect_after_login"].to_s
    if to == "/" || to[0] != "/" || to.include?("//")
      redirect_to user_path(auth.extra.raw_info.screen_name)
    else
      redirect_to to
    end
  end

  def destroy
    reset_session

    redirect_to root_path
  end
end
