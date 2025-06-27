require "rails_helper"

RSpec.describe Diary, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:diary_answers) }
    it { is_expected.to have_many(:til_candidates) }
  end

  describe "GitHub related methods" do
    let(:user) do
      User.create!(
        email: "test@example.com",
        password: "password",
        github_id: "123456",
        username: "testuser",
        access_token: "test_token",
        github_repo_name: "test-til"
      )
    end

    let(:diary) do
      user.diaries.create!(
        date: Date.current,
        notes: "Test notes",
        selected_til_index: 0
      )
    end

    let!(:til_candidate) do
      diary.til_candidates.create!(
        content: "Today I learned about testing",
        index: 0
      )
    end

    describe "#github_uploaded?" do
      context "when github_uploaded is true" do
        before { diary.update!(github_uploaded: true) }

        it "returns true" do
          expect(diary.github_uploaded?).to be true
        end
      end

      context "when github_uploaded is false" do
        before { diary.update!(github_uploaded: false) }

        it "returns false" do
          expect(diary.github_uploaded?).to be false
        end
      end

      context "when github_uploaded is nil" do
        before { diary.update!(github_uploaded: nil) }

        it "returns false" do
          expect(diary.github_uploaded?).to be false
        end
      end
    end

    describe "#can_upload_to_github?" do
      context "when all conditions are met" do
        it "returns true" do
          expect(diary.can_upload_to_github?).to be true
        end
      end

      context "when already uploaded" do
        before { diary.update!(github_uploaded: true) }

        it "returns false" do
          expect(diary.can_upload_to_github?).to be false
        end
      end

      context "when user has no repository configured" do
        before { user.update!(github_repo_name: nil) }

        it "returns false" do
          expect(diary.can_upload_to_github?).to be false
        end
      end

      context "when no TIL is selected" do
        before { diary.update!(selected_til_index: nil) }

        it "returns false" do
          expect(diary.can_upload_to_github?).to be false
        end
      end
    end

    describe "#selected_til_content" do
      context "when TIL is selected" do
        it "returns the content of selected TIL candidate" do
          expect(diary.selected_til_content).to eq("Today I learned about testing")
        end
      end

      context "when selected_til_index is nil" do
        before { diary.update!(selected_til_index: nil) }

        it "returns nil" do
          expect(diary.selected_til_content).to be_nil
        end
      end

      context "when TIL candidate does not exist for the index" do
        before { diary.update!(selected_til_index: 999) }

        it "returns nil" do
          expect(diary.selected_til_content).to be_nil
        end
      end
    end
  end
end
