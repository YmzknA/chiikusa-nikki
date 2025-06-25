class HomeController < ApplicationController
  def index
    if current_user
      redirect_to diaries_path
    end
  end
end
