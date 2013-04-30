class IController < ApplicationController
  # GET /api/tweets/import
  def import
    # import 100
    if session[:account]
      session[:account].import_favorites(params[:id].to_i)
    else
      raise Aclog::Exceptions::LoginRequired
    end
  end
end
