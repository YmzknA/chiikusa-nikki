require "rails_helper"

RSpec.describe TilCandidate, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:diary) }
  end

  describe "validations" do
    let(:diary) { create(:diary) }
    let(:til_candidate) { build(:til_candidate, diary: diary) }

    context "when valid attributes" do
      it "is valid with all required attributes" do
        expect(til_candidate).to be_valid
      end
    end

    context "when missing diary" do
      it "is invalid without diary" do
        til_candidate.diary = nil
        expect(til_candidate).not_to be_valid
      end
    end

    context "content validation scenarios" do
      it "is valid with empty content" do
        til_candidate.content = ""
        expect(til_candidate).to be_valid
      end

      it "is valid with nil content" do
        til_candidate.content = nil
        expect(til_candidate).to be_valid
      end

      it "handles very long content" do
        til_candidate.content = "A" * 10_000
        expect(til_candidate).to be_valid
      end
    end

    context "index validation scenarios" do
      it "is valid with integer index" do
        til_candidate.index = 0
        expect(til_candidate).to be_valid
      end

      it "is valid with nil index" do
        til_candidate.index = nil
        expect(til_candidate).to be_valid
      end

      it "is valid with negative index" do
        til_candidate.index = -1
        expect(til_candidate).to be_valid
      end
    end
  end

  describe "business logic" do
    let(:diary) { create(:diary, :with_til_candidates) }
    let(:til_candidates) { diary.til_candidates.order(:index) }

    describe "content generation patterns" do
      it "generates diverse content across different candidates" do
        contents = til_candidates.map(&:content)
        expect(contents.uniq.size).to eq(contents.size)
      end

      it "maintains consistent structure in content" do
        til_candidates.each do |candidate|
          expect(candidate.content).to be_present
          expect(candidate.content.length).to be > 10
        end
      end
    end

    describe "indexing behavior" do
      it "maintains proper index ordering" do
        indexes = til_candidates.map(&:index)
        expect(indexes).to eq([0, 1, 2])
      end

      it "allows custom index values" do
        custom_candidate = create(:til_candidate, diary: diary, index: 10)
        expect(custom_candidate.index).to eq(10)
      end
    end

    describe "diary relationship" do
      it "belongs to the correct diary" do
        til_candidates.each do |candidate|
          expect(candidate.diary).to eq(diary)
        end
      end

      it "is destroyed when diary is destroyed" do
        candidate_ids = til_candidates.pluck(:id)
        diary.destroy

        candidate_ids.each do |id|
          expect(TilCandidate.find_by(id: id)).to be_nil
        end
      end
    end
  end

  describe "factory validations" do
    it "creates valid til_candidate with factory" do
      til_candidate = build(:til_candidate)
      expect(til_candidate).to be_valid
    end

    it "creates valid first TIL candidate" do
      til_candidate = build(:til_candidate, :first)
      expect(til_candidate).to be_valid
      expect(til_candidate.index).to eq(0)
      expect(til_candidate.content).to include("test-driven development")
    end

    it "creates valid second TIL candidate" do
      til_candidate = build(:til_candidate, :second)
      expect(til_candidate).to be_valid
      expect(til_candidate.index).to eq(1)
      expect(til_candidate.content).to include("refactoring patterns")
    end

    it "creates valid third TIL candidate" do
      til_candidate = build(:til_candidate, :third)
      expect(til_candidate).to be_valid
      expect(til_candidate.index).to eq(2)
      expect(til_candidate.content).to include("database optimization")
    end
  end

  describe "edge cases and error handling" do
    let(:diary) { create(:diary) }

    describe "data integrity" do
      it "handles encoding issues gracefully" do
        til_candidate = create(:til_candidate,
                               diary: diary,
                               content: "Test with special chars: 日本語 émoji 🚀")
        expect(til_candidate.reload.content).to include("日本語")
      end

      it "preserves markdown formatting" do
        markdown_content = "## Header\n\n- List item\n- Another item\n\n```ruby\ncode block\n```"
        til_candidate = create(:til_candidate, diary: diary, content: markdown_content)
        expect(til_candidate.reload.content).to include("## Header")
        expect(til_candidate.reload.content).to include("```ruby")
      end
    end

    describe "performance considerations" do
      it "handles bulk creation efficiently" do
        candidates_data = 100.times.map do |i|
          { diary: diary, index: i, content: "Content #{i}" }
        end

        expect do
          TilCandidate.create!(candidates_data)
        end.to change(TilCandidate, :count).by(100)
      end
    end
  end
end
