module SecurityHeaders
  extend ActiveSupport::Concern

  included do
    before_action :set_csp_header
  end

  def set_csp_header
    policy = {
      "default-src" => "'self'",
      "img-src" => "'self' https://pbs.twimg.com https://abs.twimg.com",
      "style-src" => "'self' http://fonts.googleapis.com",
      "font-src" => "'self' http://fonts.gstatic.com",
      "frame-src" => "'self' http://platform.twitter.com"
    }
    policy_str = policy.map {|k, v| "#{k} #{v}" }.join("; ")
    response["Content-Security-Policy"] = policy_str
  end
end
