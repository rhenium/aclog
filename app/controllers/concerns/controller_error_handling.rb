module ControllerErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |exception|
      message = "\n#{exception.class} (#{exception.message}):\n"
      message << exception.annoted_source_code.to_s if exception.respond_to?(:annoted_source_code)
      message << "  " << exception.backtrace.join("\n  ")
      logger.fatal("#{message}\n\n")
      @details = message if Rails.env.development?

      @message = "#{t("error.internal_error")}: #{request.uuid}"
      render "errors/common_error", status: 500, formats: :html
    end

    rescue_from \
      ActionController::RoutingError,
      ActionView::MissingTemplate,
      ActiveRecord::RecordNotFound,
      Aclog::Exceptions::NotFound,
      Twitter::Error::NotFound do |exception|
      @message = t("error.not_found")
      render "errors/common_error", status: 404, formats: :html
    end

    rescue_from \
      Aclog::Exceptions::Forbidden,
      Twitter::Error::Unauthorized,
      Twitter::Error::Forbidden do |exception|
      if @user
        @message = t("error.forbidden")
        @sidebars = [:user]
      else
        @message = t("error.forbidden")
      end
      render "errors/common_error", status: 403, formats: :html
    end
  end
end
