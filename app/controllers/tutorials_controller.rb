class TutorialsController < ApplicationController
  before_action :authenticate_user!

  def show
    # チュートリアルページを表示する
  end
end
