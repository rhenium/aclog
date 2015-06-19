class SettingsController < ApplicationController
  before_action :set_account

  def index
  end

  def update
    @account.update(notification_enabled: !!params[:notification_enabled])
    redirect_to action: "index"
  end

  def confirm_deactivation
  end

  def deactivate
    @account.status = Account::INACTIVE
    @account.save!

    begin
      WorkerManager.update_account(@account)
    rescue Aclog::Exceptions::WorkerConnectionError
    end

    reset_session
  end

  private
  def set_account
    return redirect_to "/i/login?redirect_after_login=" + CGI.escape(url_for(only_path: true)) unless logged_in?

    @account = current_user.account
  end
end
