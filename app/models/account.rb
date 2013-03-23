class Account < ActiveRecord::Base
  def user
    User.cached(user_id)
  end
end
