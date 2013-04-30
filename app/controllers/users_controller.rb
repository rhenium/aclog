class UsersController < ApplicationController
  def info
    user_required
    @description = "Profile"
    @stats = @user.stats(true)
  end

  def discovered_by
    user_required
    @usermap = @user.count_discovered_by
    render "shared/user_ranking"
  end

  def discovered_of
    user_required
    @usermap = @user.count_discovered_of
    render "shared/user_ranking"
  end

  private
  def user_required
    @user = _get_user(params[:id] || params[:user_id], params[:screen_name])
    raise Aclog::Exceptions::UserNotFound unless @user
  end
end
