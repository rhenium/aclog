class SettingsController < ApplicationController
  before_action :set_account

  def index
  end

  def update
    @account.update(notification_enabled: params[:notification_enabled] == "true")
    redirect_to action: "index"
  end

  def confirm_deactivation
  end

  def deactivate
    @account.deactivate!

    begin
      WorkerManager.update_account(self)
    rescue Aclog::Exceptions::WorkerConnectionError
    end

    reset_session
  end

  private
  def set_account
    return redirect_to "/i/login" unless logged_in?
    @account = current_user.account
  end
end
