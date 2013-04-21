require "time"
module UsersHelper
  def format_date_ago(dt)
    "#{(DateTime.now.utc - dt.to_datetime).to_i}d ago"
  end
end
