class SettingsController < ApplicationController
  before_filter :authenticate!
  layout "index"

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
  def authenticate!
    raise Aclog::Exceptions::LoginRequired unless session[:user_id]
    @account = session[:account]
  end
end
