module SecurityHeaders
  extend ActiveSupport::Concern

  included do
    before_action :set_cors if Rails.env.development?
  end

  def set_cors
    response["Access-Control-Allow-Origin"] = request.headers["Origin"]
    response["Access-Control-Allow-Credentials"] = "true"
  end
end
