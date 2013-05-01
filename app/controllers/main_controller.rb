class MainController < ApplicationController
  def index
    @title = "aclog"
    render layout: "index"
  end

  def about
    @title = "about"
  end

  def api
    @title = "about api"
  end
end
