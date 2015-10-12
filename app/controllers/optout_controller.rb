class OptoutController < ApplicationController
  include OAuthUtils

  def index
  end

  def create
    oauth_redirect(optout_callback_url)
  end

  def callback
    access_token = oauth_verify!

    account = Account.register(user_id: access_token.params[:user_id],
                               oauth_token: access_token.token,
                               oauth_token_secret: access_token.secret)
    account.opted_out!
    reset_session if logged_in?
  end

  def destroy
    if logged_in? && current_user.opted_out?
      current_user.account.active!
      begin
        WorkerManager.update_account(account)
      rescue Aclog::Exceptions::WorkerConnectionError
      end
    else
      raise Aclog::Exceptions::Forbidden
    end
  end
end
