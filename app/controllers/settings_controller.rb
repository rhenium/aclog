class SettingsController < ApplicationController
  before_action :set_account

  def index
  end

  def update
    @account.update_settings!(notification: params[:notification] == "true",
                              private: params[:private] == "true")
    redirect_to action: "index"
  end

  def confirm_deactivation
  end

  def deactivate
    @account.deactivate!
    reset_session
  end

  private
  def set_account
    @account = logged_in? && current_user.account
    raise Aclog::Exceptions::LoginRequired unless @account
  end
end
