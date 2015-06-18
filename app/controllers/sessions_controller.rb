class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]

    account = Account.register(user_id: auth.uid,
                               oauth_token: auth.credentials.token,
                               oauth_token_secret: auth.credentials.secret)
    User.create_or_update_from_json(
      { id: account.user_id,
        screen_name: auth.extra.raw_info.screen_name,
        name: auth.extra.raw_info.name,
        profile_image_url_https: auth.extra.raw_info.profile_image_url_https,
        protected: auth.extra.raw_info.protected })

    begin
      WorkerManager.update_account(account)
    rescue Aclog::Exceptions::WorkerConnectionError
    end

    session[:user_id] = account.user_id

    to = request.env["omniauth.params"]["redirect_after_login"].to_s
    if safe_redirect?(to)
      redirect_to to
    else
      redirect_to user_path(auth.extra.raw_info.screen_name)
    end
  end

  def destroy
    reset_session

    redirect_to root_path
  end
end
