require "socket"

class SessionsController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]
    user = Account.find_or_initialize_by(:user_id => auth["uid"])
    user.update_attributes(:oauth_token => auth["credentials"]["token"],
                           :oauth_token_secret => auth["credentials"]["secret"])
    session[:user_id] = user.user_id
    session[:screen_name] = auth["info"]["nickname"]

    UNIXSocket.open(Settings.register_server_path) do |socket|
      socket.write "REGISTER #{user.id}\r\n"
    end

    redirect_to root_url
  end

  def destroy
    reset_session

    redirect_to root_url
  end
end
