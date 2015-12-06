class UsersController < ApplicationController
  before_action :load_user, only: [:favorited_by, :favorited_users]
  before_action :require_registered!, only: [:favorited_by, :favorited_users]

  def suggest_screen_name
    users = User.suggest_screen_name(params[:head].to_s).order(:screen_name).limit(10)
    render_json data: users
  end

  def stats_compact
    @user = User.find(screen_name: params[:screen_name])
    render_json data: @user.stats.to_h
  end

  def favorited_by
    data = @user.count_favorited_by
    render_json data: format_favorited_by(data)
  end

  def favorited_users
    data = @user.count_favorited_users
    render_json data: format_favorited_by(data)
  end

  def lookup
    sns = params[:screen_name].split(",")
    queried = User.where(screen_name: sns).map { |u| [u.screen_name, u] }.to_h
    render_json data: sns.map { |sn| queried[sn] }
  end

  private
  def format_favorited_by(data)
    tops = data.take(Settings.users.count)
    cached_users = User.find(tops.map {|k, v| k }).map {|user| [user.id, user] }.to_h
    all_reactions = data.inject(0) {|sum, (k, v)| sum + v }

    { users_count: data.size,
      reactions_count: all_reactions,
      user: @user.as_json(methods: :registered),
      users: tops.reverse_each.map { |user_id, count|
        u = cached_users[user_id]
        { user_id: user_id,
          count: count,
          name: u.name,
          screen_name: u.screen_name,
          profile_image_url: u.profile_image_url } } }
  end

  def load_user
    @user = authorize! User.find(screen_name: params[:screen_name])
  end

  def require_registered!
    @user.registered? || raise(Aclog::Exceptions::UserNotRegistered)
  end
end
