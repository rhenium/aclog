class SessionsController < ApplicationController
  include OAuthUtils

  def redirect
    render_json data: { redirect: oauth_redirect }
  end

  def callback
    account = oauth_callback

    begin
      WorkerManager.update_account(account)
      render_json data: { collector_updated: true }
    rescue Aclog::Exceptions::WorkerConnectionError
      render_json data: { collector_updated: false }
    end
  end

  def destroy
    session.delete(:user_id)
    render_json data: { }
  end

  def verify
    render_json data: { }
  end
end
