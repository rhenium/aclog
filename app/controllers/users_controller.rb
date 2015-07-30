class UsersController < ApplicationController
  def stats
    authorize! @user = User.find(screen_name: params[:screen_name])
    @user.require_registered!
    @discovered_by = @user.count_discovered_by
    @discovered_users = @user.count_discovered_users
    @sidebars = [:user]
  end

  def i_stats
    user = User.find(screen_name: params[:screen_name])
    render json: user.stats.to_h
  end

  def i_suggest_screen_name
    users = User.suggest_screen_name(params[:head].to_s).limit(10)
    filtered = users.map {|user| { name: user.name, screen_name: user.screen_name, profile_image_url: user.profile_image_url(:mini) } }
    render json: filtered
  end
end
