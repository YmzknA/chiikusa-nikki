require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "returns http success for root path" do
      get "/"
      expect(response).to have_http_status(:success)
    end

    it "renders the home page" do
      get "/"
      expect(response.body).to include("html")
    end

    it "does not require authentication" do
      get "/"
      expect(response).not_to redirect_to(new_user_session_path)
    end
  end

end
