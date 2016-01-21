module ControllerErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |exception|
      if Rails.env.development?
        message = "#{exception.class} (#{exception.message}):\n"
        message << exception.annoted_source_code.to_s if exception.respond_to?(:annoted_source_code)
        message << "  " << exception.backtrace.join("\n  ")
        logger.fatal("\n#{message}\n\n")
      else
        message = "Internal Server Error: #{request.uuid}"
      end

      render_json data: { error: { message: message } }, status: 500
    end

    rescue_from \
      ActionController::RoutingError,
      AbstractController::ActionNotFound,
      ActiveRecord::RecordNotFound,
      Aclog::Exceptions::NotFound,
      Twitter::Error::NotFound do |exception|
      message = "Page or object not found (#{exception.message})"
      render_json data: { error: { message: message } }, status: 404
    end

    rescue_from \
      Aclog::Exceptions::Forbidden,
      Twitter::Error::Unauthorized,
      Twitter::Error::Forbidden do |exception|
      message = "You are not authorized to access this page"
      render_json data: { error: { message: message } }, status: 403
    end

    rescue_from Aclog::Exceptions::WorkerConnectionError do |ex|
      message = "Unable to connect to collector service (is down?)"
      render_json data: { error: { message: message } }, status: 500
    end
  end
end
