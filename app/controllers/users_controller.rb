class UsersController < ApplicationController
  def discovered_by
    authorize! @user = User.find(screen_name: params[:screen_name])
    @user.require_registered!
    @result = @user.count_discovered_by.take(Settings.users.count)
    @cached_users = User.find(@result.map(&:first)).map {|user| [user.id, user] }.to_h

    @sidebars = [:user]
  end

  def discovered_users
    authorize! @user = User.find(screen_name: params[:screen_name])
    @user.require_registered!
    @result = @user.count_discovered_users.take(Settings.users.count)
    @cached_users = User.find(@result.map(&:first)).map {|user| [user.id, user] }.to_h

    @sidebars = [:user]
  end

  def i_suggest_screen_name
    sleep 1 if Rails.env.development?
    users = User.suggest_screen_name(params[:head].to_s).limit(10)
    filtered = users.map {|user| { name: user.name, screen_name: user.screen_name, profile_image_url: user.profile_image_url(:mini) } }
    render json: filtered
  end

  def stats
    user = User.find(screen_name: params[:screen_name])
    render json: user.stats.to_h
  end
end
