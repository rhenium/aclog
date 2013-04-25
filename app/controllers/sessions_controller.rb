require "socket"

class SessionsController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]

    account = Account.create_or_update(user_id: auth["uid"],
                                       oauth_token: auth["credentials"]["token"],
                                       oauth_token_secret: auth["credentials"]["secret"],
                                       consumer_version: Settings.consumer_version)
    session[:account] = account
    session[:user_id] = account.user_id

    begin
      UNIXSocket.open(Settings.register_server_path) do |socket|
        socket.write({type: "register",
                      id: account.id,
                      user_id: account.user_id}.to_msgpack)
      end
    rescue Exception
      # receiver not started?
      warn $!
      warn $@
    end

    redirect_to root_path
  end

  def destroy
    reset_session

    redirect_to root_path
  end
end
