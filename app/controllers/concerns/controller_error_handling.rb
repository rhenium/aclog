module ControllerErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |exception|
      @message = "#{t("error.internal_error")}: #{exception.class}"
      render "shared/common_error", status: 500, formats: :html
    end

    rescue_from Aclog::Exceptions::Forbidden do |exception|
      @message = t("error.forbidden")
      render "shared/common_error", status: 403, formats: :html
    end

    rescue_from Aclog::Exceptions::UserProtected do |exception|
      @message = t("error.forbidden")
      render "shared/user_forbidden_error", status: 403, formats: :html
    end

    rescue_from ActionController::RoutingError, ActiveRecord::RecordNotFound, Aclog::Exceptions::NotFound do |exception|
      @message = t("error.not_found")
      render "shared/common_error", status: 404, formats: :html
    end

    rescue_from ActionView::MissingTemplate do
      if request.format != :html
        @message = t("error.not_found")
        render "shared/common_error", status: 404, formats: :html
      end
    end
  end
end
