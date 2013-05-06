class UsersController < ApplicationController
  def stats
    user_required
    @caption = "Profile"
    @user_stats = @user.stats
    @user_twitter = @user.account.client.user if request.format == :html
  end

  def discovered_by
    user_required
    @result = @user.count_discovered_by.take(50)
    @caption = "Discovered By"
    render "_user_ranking"
  end

  def discovered_users
    user_required
    @result = @user.count_discovered_users.take(50)
    @caption = "Discovered Users"
    render "_user_ranking"
  end

  def screen_name
    raise ActionController::RoutingError unless params[:user_id]
    user_ids = params[:user_id].split(/,/).map(&:to_i)
    result = User.where("id IN (?)", user_ids).map {|user| {id: user.id, screen_name: user.screen_name} }
    render json: result
  end

  private
  def user_required
    @user = _get_user(params[:id] || params[:user_id], params[:screen_name])
    raise Aclog::Exceptions::UserNotFound unless @user
    raise Aclog::Exceptions::UserProtected unless authorized_to_show?(@user)
  end
end
