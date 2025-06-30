require 'rails_helper'

RSpec.describe "Tutorials", type: :request do
  describe "GET /tutorial" do
    context "when user is not signed in" do
      it "redirects to root page" do
        get tutorial_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when user is signed in" do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it "returns success" do
        get tutorial_path
        expect(response).to have_http_status(:success)
      end

      it "renders the tutorial page" do
        get tutorial_path
        expect(response.body).to include("ちいくさ日記の使い方")
        expect(response.body).to include("プログラミング学習を雑草と一緒に記録しよう")
      end

      it "includes all tutorial sections" do
        get tutorial_path
        expect(response.body).to include("日記の作り方")
        expect(response.body).to include("AIでTILを自動生成")
        expect(response.body).to include("GitHub連携で草を生やそう")
        expect(response.body).to include("学習の振り返り")
        expect(response.body).to include("みんなの頑張りを見る")
      end

      it "includes navigation links" do
        get tutorial_path
        expect(response.body).to include("日記を書く")
        expect(response.body).to include("閉じる")
      end
    end
  end
end