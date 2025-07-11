require "rails_helper"

RSpec.describe "Reactions", type: :request do
  let(:user) { create(:user) }
  let(:diary) { create(:diary, user: user, is_public: true) }

  before { sign_in user }

  describe "POST /diaries/:diary_id/reactions" do
    let(:valid_emoji) { "😂" }
    let(:invalid_emoji) { "invalid" }

    context "with valid parameters" do
      it "creates a new reaction" do
        expect do
          post diary_reactions_path(diary), params: { reaction: { emoji: valid_emoji } },
                                            headers: { "Accept" => "text/vnd.turbo-stream.html" }
        end.to change(Reaction, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "updates the reaction display" do
        post diary_reactions_path(diary), params: { reaction: { emoji: valid_emoji } },
                                          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include("reactions_#{diary.id}")
      end
    end

    context "with invalid parameters" do
      it "does not create a reaction with invalid emoji" do
        expect do
          post diary_reactions_path(diary), params: { reaction: { emoji: invalid_emoji } },
                                            headers: { "Accept" => "text/vnd.turbo-stream.html" }
        end.not_to change(Reaction, :count)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "does not create duplicate reactions" do
        create(:reaction, user: user, diary: diary, emoji: valid_emoji)

        expect do
          post diary_reactions_path(diary), params: { reaction: { emoji: valid_emoji } },
                                            headers: { "Accept" => "text/vnd.turbo-stream.html" }
        end.not_to change(Reaction, :count)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to root page" do
        post diary_reactions_path(diary), params: { reaction: { emoji: valid_emoji } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /diaries/:diary_id/reactions/:id" do
    let(:emoji) { "😂" }
    let!(:reaction) { create(:reaction, user: user, diary: diary, emoji: emoji) }

    context "when reaction exists" do
      it "destroys the reaction" do
        expect do
          delete diary_reaction_path(diary, emoji), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        end.to change(Reaction, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "updates the reaction display" do
        delete diary_reaction_path(diary, emoji), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include("reactions_#{diary.id}")
      end
    end

    context "when reaction does not exist" do
      it "returns not found" do
        delete diary_reaction_path(diary, "nonexistent"), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to root page" do
        delete diary_reaction_path(diary, emoji)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
