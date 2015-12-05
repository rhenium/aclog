class SettingsController < ApplicationController
  before_action :set_account

  def get
    render_json data: { notification_enabled: @account.notification_enabled }
  end

  def update
    @account.update(notification_enabled: !!params[:notification_enabled])
    render_json data: { notification_enabled: @account.notification_enabled }
  end

  def confirm_deactivation
  end

  def deactivate
    @account.inactive!

    begin
      WorkerManager.update_account(@account)
    rescue Aclog::Exceptions::WorkerConnectionError
    end

    reset_session
  end

  private
  def set_account
    raise Aclog::Exceptions::Unauthorized unless logged_in?
    @account = current_user.account
  end
end
