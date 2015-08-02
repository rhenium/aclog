class Internal::UsersController < Internal::ApplicationController
  def suggest_screen_name
    users = User.suggest_screen_name(params[:head].to_s).limit(10)
    filtered = users.map {|user| { name: user.name, screen_name: user.screen_name, profile_image_url: user.profile_image_url(:mini) } }
    render json: filtered
  end

  def stats_compact
    user = User.find(screen_name: params[:screen_name])
    render json: user.stats.to_h
  end

  def favorited_by
    authorize! @user = User.find(screen_name: params[:screen_name])
    @user.require_registered!
    @data = @user.count_favorited_by
    render :favorited_by
  end

  def favorited_users
    authorize! @user = User.find(screen_name: params[:screen_name])
    @user.require_registered!
    @data = @user.count_favorited_users
    render :favorited_by
  end
end
