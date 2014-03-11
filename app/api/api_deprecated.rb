class ApiDeprecated < Grape::API
  resource :tweets do
    params_user = -> do
      params do
        optional :user_id, type: Integer
        optional :screen_name, type: String
      end
    end

    params_user_b = -> do
      params do
        optional :user_id_b, type: Integer
        optional :screen_name_b, type: String
      end
    end

    params_pagination = -> do
      params do
        optional :count, type: Integer
        optional :page, type: Integer
      end
    end

    params_pagination_with_ids = -> do
      params_pagination[]
      params do
        optional :since_id, type: Integer
        optional :max_id, type: Integer
      end
    end

    helpers do
      def user
        @_user ||= begin
          user = User.find(id: params[:user_id], screen_name: params[:screen_name])
          raise Aclog::Exceptions::UserProtected unless permitted_to_see?(user)
          user
        end
      end

      def paginate(tweets)
        count = [(params[:count] || Settings.tweets.count.default).to_i, Settings.tweets.count.max].min
        tweets.page((params[:page] || 1).to_i, count)
      end

      def paginate_with_ids(tweets)
        paginate(tweets).max_id(params[:max_id]).since_id(params[:since_id])
      end
    end

    desc "Deprecated. Use GET tweets/user_best", deprecated: true
    params_user[]
    params_pagination[]
    get "best", rabl: "tweets" do
      @tweets = paginate user.tweets.reacted.order_by_reactions
    end

    desc "Deprecated. Use GET tweets/user_timeline", deprecated: true
    params_user[]
    params_pagination_with_ids[]
    get "timeline", rabl: "tweets" do
      @tweets = paginate_with_ids user.tweets.reacted.order_by_id
    end

    desc "Deprecated. Use GET tweets/user_discoveries", deprecated: true
    params_user[]
    params_pagination_with_ids[]
    get "discoveries", rabl: "tweets" do
      @tweets = paginate_with_ids(Tweet).discovered_by(user).order_by_id
    end

    desc "Deprecated. Use GET tweets/user_discovered_by", deprecated: true
    params_user[]
    params_user_b[]
    params_pagination_with_ids[]
    get "discovered_by", rabl: "tweets" do
      @tweets = paginate_with_ids(user.tweets).discovered_by(user_b).order_by_id
    end
  end
end

