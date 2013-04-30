class IController < ApplicationController
  # GET /i/import
  def import
    # import 100
    if session[:account]
      session[:account].import_favorites(params[:id].to_i)
    else
      raise Aclog::Exceptions::LoginRequired
    end

    redirect_to tweet_path(params[:id])
  end
end
