class UsersController < ApplicationController
  def stats
    @user = require_user
  end

  def discovered_by
    @user = require_user
    authorize_to_show_user_best! @user
    @result = @user.count_discovered_by.take(Settings.users.count)
    @cached_users = Hash[User.find(@result.map {|user_id, count| user_id }).map {|user| [user.id, user] }]
  end

  def discovered_users
    @user = require_user
    authorize_to_show_user_best! @user
    @result = @user.count_discovered_users.take(Settings.users.count)
    @cached_users = Hash[User.find(@result.map {|user_id, count| user_id }).map {|user| [user.id, user] }]
  end

  def user_jump_suggest
    render json: User.where("screen_name LIKE ?", "#{params[:head].to_s.delete("%_")}%").order(screen_name: :asc).limit(10).pluck(:screen_name)
  end

  private
  def require_user
    User.find(id: (params[:id] || params[:user_id]), screen_name: params[:screen_name])
  end
end
