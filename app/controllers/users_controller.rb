class UsersController < ApplicationController
  def stats
    @user = require_user
  end

  def discovered_by
    @user = require_user
    authorize_to_show_user_best! @user
    @result = @user.count_discovered_by.take(Settings.users.count)
    @cached_users = User.find(@result.map(&:first)).map {|user| [user.id, user] }.to_h
  end

  def discovered_users
    @user = require_user
    authorize_to_show_user_best! @user
    @result = @user.count_discovered_users.take(Settings.users.count)
    @cached_users = User.find(@result.map(&:first)).map {|user| [user.id, user] }.to_h
  end

  def user_jump_suggest
    users = User.suggest_screen_name(params[:head].to_s).limit(10)
    filtered = users.map {|user| { name: user.name, screen_name: user.screen_name, profile_image_url: user.profile_image_url(:mini) } }
    render json: filtered
  end

  private
  def require_user
    User.find(id: (params[:id] || params[:user_id]), screen_name: params[:screen_name])
  end
end
