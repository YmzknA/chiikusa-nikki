require "rails_helper"

RSpec.describe Diary, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:diary_answers).dependent(:destroy) }
    it { is_expected.to have_many(:til_candidates).dependent(:destroy) }
  end

  describe "validations" do
    let(:user) { create(:user) }
    let(:diary) { build(:diary, user: user) }

    it { is_expected.to validate_presence_of(:date) }

    describe "date uniqueness" do
      it "validates uniqueness of date scoped to user" do
        create(:diary, user: user, date: Date.current)
        duplicate_diary = build(:diary, user: user, date: Date.current)

        expect(duplicate_diary).not_to be_valid
        expect(duplicate_diary.errors[:date]).to include("の日記は既に作成されています")
      end

      it "allows same date for different users" do
        other_user = create(:user, github_id: "different_id")
        create(:diary, user: user, date: Date.current)
        diary_for_other_user = build(:diary, user: other_user, date: Date.current)

        expect(diary_for_other_user).to be_valid
      end
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:public_diary) { create(:diary, :public, user: user) }
    let!(:private_diary) { create(:diary, user: user, is_public: false) }

    describe ".public_diaries" do
      it "returns only public diaries" do
        expect(Diary.public_diaries).to include(public_diary)
        expect(Diary.public_diaries).not_to include(private_diary)
      end
    end

    describe ".private_diaries" do
      it "returns only private diaries" do
        expect(Diary.private_diaries).to include(private_diary)
        expect(Diary.private_diaries).not_to include(public_diary)
      end
    end
  end

  describe "GitHub functionality" do
    let(:user) { create(:user, :with_github, :with_github_repo) }
    let(:diary) { create(:diary, :with_selected_til, user: user) }

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

      context "when github_uploaded is false" do
        before { diary.update!(github_uploaded: false) }

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
    end

    describe "#selected_til_content" do
      let(:diary_with_tils) { create(:diary, :with_til_candidates, user: user) }

      context "when TIL is selected" do
        it "returns the content of selected TIL candidate" do
          diary_with_tils.update!(selected_til_index: 0)
          expect(diary_with_tils.selected_til_content).to be_present
        end
      end

      context "when selected_til_index is nil" do
        before { diary_with_tils.update!(selected_til_index: nil) }

        it "returns nil" do
          expect(diary_with_tils.selected_til_content).to be_nil
        end
      end

      context "when TIL candidate does not exist for the index" do
        before { diary_with_tils.update!(selected_til_index: 999) }

        it "returns nil" do
          expect(diary_with_tils.selected_til_content).to be_nil
        end
      end
    end
  end

  describe "factory validations" do
    it "creates valid diary with factory" do
      diary = build(:diary)
      expect(diary).to be_valid
    end

    it "creates valid public diary" do
      diary = build(:diary, :public)
      expect(diary).to be_valid
      expect(diary.is_public).to be true
    end

    it "creates valid diary with GitHub upload status" do
      diary = build(:diary, :github_uploaded)
      expect(diary).to be_valid
      expect(diary.github_uploaded).to be true
      expect(diary.github_uploaded_at).to be_present
    end

    it "creates valid diary with TIL candidates" do
      diary = create(:diary, :with_til_candidates)
      expect(diary.til_candidates.count).to eq(3)
    end

    it "creates valid diary with selected TIL" do
      diary = create(:diary, :with_selected_til)
      expect(diary.selected_til_index).to eq(0)
      expect(diary.til_candidates.count).to eq(3)
      expect(diary.selected_til_content).to be_present
    end
  end
end
