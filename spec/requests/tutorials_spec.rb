require "rails_helper"

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
        expect(response.body).to include("毎日１分、簡単日記で草生やし")
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
        expect(response.body).to include("AIでTILを自動生成")
      end

      context "when username is not configured" do
        let(:user) { create(:user, username: User::DEFAULT_USERNAME) }

        it "redirects to username setup" do
          get tutorial_path
          expect(response).to redirect_to(setup_username_path)
        end
      end

      context "with invalid tutorial step parameter" do
        it "handles invalid step gracefully" do
          get tutorial_path, params: { step: 99 }
          expect(response).to redirect_to(diaries_path)
          follow_redirect!
          expect(response.body).to include("指定されたチュートリアルステップが見つかりません")
        end
      end

      context "when tutorial data is missing" do
        before do
          allow(I18n).to receive(:t).and_raise(I18n::MissingTranslationData.new(:ja, "test"))
        end

        it "uses fallback tutorial data" do
          get tutorial_path
          expect(response).to have_http_status(:success)
        end
      end

      context "error handling" do
        before do
          controller = TutorialsController
          allow_any_instance_of(controller).to receive(:load_tutorial_steps)
                                           .and_raise(StandardError.new("Test error"))
        end

        it "handles general errors gracefully" do
          get tutorial_path
          expect(response).to redirect_to(diaries_path)
          follow_redirect!
          expect(response.body).to include("チュートリアルの読み込み中にエラーが発生しました")
        end
      end
    end
  end
end
