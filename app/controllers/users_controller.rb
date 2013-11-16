class UsersController < ApplicationController
  def stats
    user_required
    @caption = "Profile"
    @user_stats = @user.stats
    @user_twitter = @user.account.client.user if request.format == :html
  end

  def discovered_by
    user_required
    authorize_to_show_best!(@user)
    @result = @user.count_discovered_by.take(Settings.user_ranking.count)
    @caption = "Discovered By"
    render "_user_ranking"
  end

  def discovered_users
    user_required
    authorize_to_show_best!(@user)
    @result = @user.count_discovered_users.take(Settings.user_ranking.count)
    @caption = "Discovered Users"
    render "_user_ranking"
  end

  def screen_name
    user_ids = (params[:id] || params[:user_id]).to_s.split(",").map(&:to_i)
    result = User.where(id: user_ids).pluck(:id, :screen_name).map {|id, screen_name| {id: id, screen_name: screen_name} }
    render json: result
  end

  private
  def user_required
    @user = User.get(params[:id] || params[:user_id], params[:screen_name])
    raise Aclog::Exceptions::UserNotFound unless @user
  end
end
