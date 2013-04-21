class MainController < ApplicationController
  def index
    @title = "aclog"
    render layout: "index"
  end

  def about
    @title = "about"
  end

  def api
    @title = "api"
  end
end
