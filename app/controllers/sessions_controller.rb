class SessionsController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]
    user = Account.find_or_initialize_by(:id => auth["uid"])
    user.update_attributes(:oauth_token => auth["credentials"]["token"],
                           :oauth_token_secret => auth["credentials"]["secret"])
    session[:user_id] = user.id
    session[:screen_name] = auth["info"]["nickname"]
    EM.defer do
      EM.connect("127.0.0.1", Settings.worker_port) do |client|
        def client.post_init
          p data = [:REGISTER, user.id].map(&:to_s).join(" ")
          send_data(data)
        end
      end
    end

    redirect_to root_url
  end

  def destroy
    reset_session

    redirect_to root_url
  end
end
