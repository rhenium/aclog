require "socket"

class SessionsController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]
    account = Account.find_or_initialize_by(:user_id => auth["uid"])
    account.oauth_token = auth["credentials"]["token"]
    account.oauth_token_secret = auth["credentials"]["secret"]
    account.consumer_version = Settings.consumer_version
    account.save!
    session[:user_id] = account.user_id
    session[:screen_name] = auth["info"]["nickname"]

    begin
      UNIXSocket.open(Settings.register_server_path) do |socket|
        socket.write({:type => "register", :id => account.id, :user_id => account.user_id}.to_msgpack)
      end
    rescue Errno::ECONNREFUSED
      # receiver not started?
      warn $!
      warn $@
    end

    redirect_to root_url
  end

  def destroy
    reset_session

    redirect_to root_url
  end
end
