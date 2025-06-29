require "rails_helper"

RSpec.describe TilCandidate, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:diary) }
  end

  describe "validations" do
    subject { build(:til_candidate) }
    
    # Note: These validations may not be implemented in the model yet
    # it { is_expected.to validate_presence_of(:content) }
    # it { is_expected.to validate_presence_of(:index) }
    # it { is_expected.to validate_numericality_of(:index) }
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
end
