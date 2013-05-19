class SessionsController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]

    account = Account.create_or_update(user_id: auth["uid"],
                                       oauth_token: auth["credentials"]["token"],
                                       oauth_token_secret: auth["credentials"]["secret"],
                                       consumer_version: Settings.collector.consumer_version)
    account.update_connection

    User.from_hash(id: account.user_id,
                   screen_name: auth["extra"]["raw_info"]["screen_name"],
                   name: auth["extra"]["raw_info"]["name"],
                   profile_image_url: auth["extra"]["raw_info"]["profile_image_url_https"],
                   protected: auth["extra"]["raw_info"]["protected"])

    session[:account] = account
    session[:user_id] = account.user_id

    redirect_to root_path
  end

  def destroy
    reset_session

    redirect_to root_path
  end
end
