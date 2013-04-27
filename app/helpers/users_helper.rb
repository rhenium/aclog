module UsersHelper
  def user_limit
    i = params[:limit].to_i
    if i > 0
      return i
    elsif i == -1
      return nil
    else
      if params[:action] == "show"
        return 100
      else
        return 20
      end
    end
  end
end
