class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]

    account = Account.create_or_update(user_id: auth["uid"],
                                       oauth_token: auth["credentials"]["token"],
                                       oauth_token_secret: auth["credentials"]["secret"])
    begin
      WorkerManager.update_account(account)
    rescue Aclog::Exceptions::WorkerConnectionError
    end

    User.create_from_json(id: account.user_id,
                          screen_name: auth["extra"]["raw_info"]["screen_name"],
                          name: auth["extra"]["raw_info"]["name"],
                          profile_image_url: auth["extra"]["raw_info"]["profile_image_url_https"],
                          protected: auth["extra"]["raw_info"]["protected"])

    session[:user_id] = account.user_id

    to = request.env["omniauth.params"]["redirect_after_login"].to_s
    if to.include? "//" || to[0] != "/"
      to = root_path
    end
    redirect_to to
  end

  def destroy
    reset_session

    redirect_to root_path
  end
end
