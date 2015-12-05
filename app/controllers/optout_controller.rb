class OptoutController < ApplicationController
  include OAuthUtils

  def redirect
    render_json data: { redirect: oauth_redirect }
  end

  def callback
    account = oauth_callback
    account.opted_out!
    reset_session

    render_json data: { }
  end

  # TODO:
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
