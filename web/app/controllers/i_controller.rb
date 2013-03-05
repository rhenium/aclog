class IController < ApplicationController
  def show
    id = params[:id].to_i
    @item = Tweet.find(id)
  end
end
