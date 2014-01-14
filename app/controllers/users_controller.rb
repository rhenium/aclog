class UsersController < ApplicationController
  param_group :user do
    optional :id, :integer, "The numerical ID of the user for whom to return results for."
    optional :screen_name, :string, "The username of the user for whom to return results for."
  end

  get "users/stats"
  description "Returns the stats of a user, specified by username or user ID."
  param_group :user
  def stats
    @user = require_user
  end

  get "users/discovered_by"
  description "Returns the list of the users who discovored the Tweets of a user, specified by username or user ID."
  param_group :user
  def discovered_by
    @user = require_user
    authorize_to_show_user_best! @user
    @result = @user.count_discovered_by.take(Settings.users.count)

    respond_to do |format|
      format.html do
        @cached_users = User.find(@result.map {|user_id, count| user_id }).map {|user| [user.id, user] }.to_h
      end

      format.json do
        render "_users_list"
      end
    end
  end

  get "users/discovered_users"
  description "Returns the list of the users discovored by a user, specified by username or user ID."
  param_group :user
  def discovered_users
    @user = require_user
    authorize_to_show_user_best! @user
    @result = @user.count_discovered_users.take(Settings.users.count)

    respond_to do |format|
      format.html do
        @cached_users = User.find(@result.map {|user_id, count| user_id }).map {|user| [user.id, user] }.to_h
      end

      format.json do
        render "_users_list"
      end
    end
  end

  get "users/screen_name"
  nodoc
  [:id, :ids, :user_id, :user_ids].each do |n|
    optional n, /^\d+(,\d+)*,?$/, "A comma-separated list of User IDs."
  end
  def screen_name
    user_ids = (params[:id] || params[:ids] || params[:user_id] || params[:user_ids]).split(",").map { |i| i.to_i }
    result = User.where(id: user_ids).pluck(:id, :screen_name).map { |id, screen_name| { id: id, screen_name: screen_name } }
    render json: result
  end

  private
  def require_user
    User.find(id: (params[:id] || params[:user_id]), screen_name: params[:screen_name])
  end
end
