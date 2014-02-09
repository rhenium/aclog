class ApiUsers < Grape::API
  resource :users do
    params_user = -> do
      params do
        optional :id, type: Integer, desc: "The numerical ID of the user for whom to return results for."
        optional :screen_name, type: String, desc: "The username of the user for whom to return results for."
      end
    end

    helpers do
      def user
        @_user ||= begin
          user = User.find(id: params[:id] || params[:user_id], screen_name: params[:screen_name])
          raise Aclog::Exceptions::Forbidden unless permitted_to_see?(user)
          user
        end
      end
    end

    desc "Returns the stats of a user, specified by username or user ID.", example_params: { user_id: 280414022 }
    params_user[]
    get "stats", rabl: "user_stats" do
      @user = user
    end

    desc "Returns the list of the users who discovored the Tweets of a user, specified by username or user ID.", example_params: { user_id: 99008565 }
    params_user[]
    get "discovored_by", rabl: "user_discovored_by_and_users" do
      @result = user.count_discovered_by.take(Settings.users.count)
    end

    desc "Returns the list of the users discovored by a user, specified by username or user ID.", example_params: { screen_name: "cn" }
    params_user[]
    get "discovored_users", rabl: "user_discovored_by_and_users" do
      @result = user.count_discovered_users.take(Settings.users.count)
    end

    desc "", nodoc: true, example_params: { id: "280414022,99008565" }
    params do
      requires :id, type: String
    end
    get "screen_name" do
      # does not use RABL
      user_ids = (params[:id] || params[:ids] || params[:user_id] || params[:user_ids]).split(",").map { |i| i.to_i }
      User.where(id: user_ids).pluck(:id, :screen_name).map { |id, screen_name| { id: id, screen_name: screen_name } }
    end
  end
end
