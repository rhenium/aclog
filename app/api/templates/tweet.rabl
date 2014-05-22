object @tweet

attributes :id, :user_id, :favorites_count, :retweets_count
node(:favoriters) {|obj| obj.favorites.pluck(:user_id) }
node(:retweeters) {|obj| obj.retweets.pluck(:user_id) }
