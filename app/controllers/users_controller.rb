class UsersController < ApplicationController
  def stats
    @user = require_user
  end

  def discovered_by
    @user = require_user
    authorize_to_show_user_best! @user
    @result = @user.count_discovered_by.sort_by {|user_id, count| -count }.take(Settings.users.count)
    @cached_users = Hash[User.find(@result.map {|user_id, count| user_id }).map {|user| [user.id, user] }]
  end

  def discovered_users
    @user = require_user
    authorize_to_show_user_best! @user
    @result = @user.count_discovered_users.sort_by {|user_id, count| -count }.take(Settings.users.count)
    @cached_users = Hash[User.find(@result.map {|user_id, count| user_id }).map {|user| [user.id, user] }]
  end

  def user_jump_suggest
    q = params[:head].to_s.gsub(/(_|%)/) {|x| "\\" + x }
    users = User.where("screen_name LIKE ?", "#{q}%").order(screen_name: :asc).limit(10)
    filtered = users.map {|user| { name: user.name, screen_name: user.screen_name, profile_image_url: user.profile_image_url_mini } }
    render json: filtered
  end

  private
  def require_user
    User.find(id: (params[:id] || params[:user_id]), screen_name: params[:screen_name])
  end
end
