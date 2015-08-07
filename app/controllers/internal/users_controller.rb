class Internal::UsersController < Internal::ApplicationController
  before_action :load_user, only: [:favorited_by, :favorited_users]
  before_action :require_registered!, only: [:favorited_by, :favorited_users]

  def suggest_screen_name
    users = User.suggest_screen_name(params[:head].to_s).order(:screen_name).limit(10)
    filtered = users.map {|user| { name: user.name, screen_name: user.screen_name, profile_image_url: user.profile_image_url(:mini) } }
    render json: filtered
  end

  def stats_compact
    @user = User.find(screen_name: params[:screen_name])
    render json: @user.stats.to_h
  end

  def favorited_by
    @data = @user.count_favorited_by
    render :favorited_by
  end

  def favorited_users
    @data = @user.count_favorited_users
    render :favorited_by
  end

  private
  def load_user
    @user = authorize! User.find(screen_name: params[:screen_name])
  end

  def require_registered!
    @user.registered? || raise(Aclog::Exceptions::UserNotRegistered, self)
  end
end
