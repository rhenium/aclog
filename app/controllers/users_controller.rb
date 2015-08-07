class UsersController < ApplicationController
  before_action :load_user

  def stats
    @sidebars = [:user]
  end

  private
  def load_user
    authorize! @user = User.find(screen_name: params[:screen_name])
    @user.registered? || raise(Aclog::Exceptions::UserNotRegistered, self)
  end
end
