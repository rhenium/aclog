module SecurityHeaders
  extend ActiveSupport::Concern

  included do
    before_action :set_csp_header
  end

  def set_csp_header
    policy = {
      "default-src" => "'self'",
      "img-src" => "'self' http://pbs.twimg.com https://pbs.twimg.com http://abs.twimg.com https://abs.twimg.com data:",
      "style-src" => "'self' fonts.googleapis.com",
      "font-src" => "'self' fonts.gstatic.com"
    }
    policy_str = policy.map {|k, v| "#{k} #{v}" }.join("; ")
    response["Content-Security-Policy"] = policy_str
  end
end
