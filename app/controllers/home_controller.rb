class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :privacy_policy, :terms_of_service]

  def index; end

  def privacy_policy; end

  def terms_of_service; end
end
