module Aclog
  module Twitter
    def snowflake(time)
      (time.to_datetime.to_i * 1000 - 1288834974657) << 22
    end
  end
end

