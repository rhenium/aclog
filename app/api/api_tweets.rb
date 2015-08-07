class ApiTweets < Grape::API
  resource :tweets do
    params_user = -> do
      params do
        optional :user_id, type: Integer, desc: "The numerical ID of the user for whom to return results for."
        optional :screen_name, type: String, desc: "The username of the user for whom to return results for."
      end
    end

    params_source_user = -> do
      params do
        optional :source_user_id, type: Integer, desc: "The numerical ID of the user for whom to return results for."
        optional :source_screen_name, type: String, desc: "The username of the user for whom to return results for."
      end
    end

    params_pagination = -> do
      params do
        optional :count, type: Integer, desc: "The number of tweets to retrieve. Must be less than or equal to #{Settings.tweets.count.max}, defaults to #{Settings.tweets.count.default}."
        optional :page, type: Integer, desc: "The page number of results to retrieve."
      end
    end

    params_pagination_with_ids = -> do
      params_pagination[]
      params do
        optional :since_id, type: Integer, desc: "Returns results with an ID greater than the specified ID."
        optional :max_id, type: Integer, desc: "Returns results with an ID less than or equal to the specified ID."
      end
    end

    params_reactions_threshold = -> do
      params do
        optional :reactions, type: Integer, desc: "Returns Tweets which has received reactions more than (or equal to) the specified number of times."
      end
    end

    params_recent_threshold = -> do
      params do
        optional :recent, type: String, desc: "When specified, returns only recent tweets in the term. Format is: /^\\d+[dwmy]$/"
      end
    end

    helpers do
      def user
        @_user ||= begin
          user = User.find(id: params[:user_id], screen_name: params[:screen_name])
          raise Aclog::Exceptions::UserProtected unless authorized?(user)
          user
        end
      end

      def source_user
        user = User.find(id: params[:source_user_id], screen_name: params[:source_screen_name])
        raise Aclog::Exceptions::UserProtected unless authorized?(user)
        user
      end

      def paginate(tweets)
        count = [(params[:count] || Settings.tweets.count.default).to_i, Settings.tweets.count.max].min
        tweets.page((params[:page] || 1).to_i, count)
      end

      def paginate_with_ids(tweets)
        paginate(tweets).max_id(params[:max_id]).since_id(params[:since_id])
      end
    end

    desc "Returns a single Tweet, specified by ID.", example_params: { id: 43341783446466560 }
    params do
      requires :id, type: Integer, desc: "The numerical ID of the desired Tweet."
    end
    get "show", rabl: "tweet" do
      @tweet = Tweet.find(params[:id])
      raise Aclog::Exceptions::UserProtected unless authorized?(@tweet)
    end

    desc "Returns Tweets, specified by comma-separated IDs.", example_params: { ids: "43341783446466560,340640143058825216" }
    params do
      requires :ids, type: String, regexp: /^\d+(,\d+)*$/, desc: "A comma-separated list of Tweet IDs, up to #{Settings.tweets.count.max} are allowed in a single request."
    end
    get "lookup", rabl: "tweets" do
      @tweets = Tweet.where(id: params[:ids].split(",").map(&:to_i))
      @tweets = @tweets.select {|tweet| authorized?(tweet) }
    end

    desc "Returns the best Tweets of a user, specified by username or user ID.", example_params: { user_id: 15926668, count: 2, page: 3, recent: "1m" }
    params_user[]
    params_pagination[]
    params_recent_threshold[]
    get "user_best", rabl: "tweets" do
      @tweets = paginate user.tweets.reacted.parse_recent(params[:recent]).order_by_reactions
    end

    desc "Returns the newest Tweets of a user, specified by username or user ID.", example_params: { screen_name: "toshi_a", count: 3, max_id: 432112694871605249 }
    params_user[]
    params_pagination_with_ids[]
    params_reactions_threshold[]
    get "user_timeline", rabl: "tweets" do
      @tweets = paginate_with_ids user.tweets.reacted(params[:reactions]).order_by_id
    end

    desc "Returns the Tweets which a user specified by username or user ID favorited.", example_params: { user_id: 120726371, count: 2 }
    params_user[]
    params_pagination[]
    params_reactions_threshold[]
    get "user_favorites", rabl: "tweets" do
      @tweets = paginate Tweet.reacted(params[:reactions]).favorited_by(user).order("`favorites`.`id` DESC")
    end

    desc "Returns the specified user's Tweets which another specified user favorited.", example_params: { user_id: 120726371, count: 2, source_screen_name: "haru067" }
    params_user[]
    params_source_user[]
    params_pagination_with_ids[]
    params_reactions_threshold[]
    get "user_favorited_by", rabl: "tweets" do
      @tweets = paginate_with_ids user.tweets.reacted(params[:reactions]).favorited_by(source_user).order_by_id
    end
  end
end
