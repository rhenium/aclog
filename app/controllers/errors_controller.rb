class ErrorsController < ApplicationController
  def render_error
    @exception = env["action_dispatch.exception"]
    @status = ActionDispatch::ExceptionWrapper.new(env, @exception).status_code

    respond_to do |format|
      format.html do
        render "error_#{@status}", :status => @status
      end

      format.json do
        render "error_#{@status}", :status => @status
      end
    end
  end
end
