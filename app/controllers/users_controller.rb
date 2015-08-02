class UsersController < ApplicationController
  def stats
    authorize! @user = User.find(screen_name: params[:screen_name])
    @user.require_registered!
    @sidebars = [:user]
  end
end
