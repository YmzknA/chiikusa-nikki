require "rails_helper"

RSpec.describe SeedManager, type: :service do
  let(:user) { create(:user, seed_count: 3) }
  let(:seed_manager) { described_class.new(user) }

  describe "#initialize" do
    it "sets the user" do
      expect(seed_manager.instance_variable_get(:@user)).to eq(user)
    end
  end

  describe "#sufficient_seeds?" do
    context "when user has seeds" do
      it "returns true" do
        expect(seed_manager.sufficient_seeds?).to be true
      end
    end

    context "when user has no seeds" do
      let(:user) { create(:user, seed_count: 0) }

      it "returns false" do
        expect(seed_manager.sufficient_seeds?).to be false
      end
    end
  end

  describe "#consume_seed!" do
    context "when user has sufficient seeds" do
      it "decrements seed count and returns true" do
        expect { seed_manager.consume_seed! }.to change { user.reload.seed_count }.from(3).to(2)
        expect(seed_manager.consume_seed!).to be true
      end
    end

    context "when user has no seeds" do
      let(:user) { create(:user, seed_count: 0) }

      it "does not decrement seed count and returns false" do
        expect { seed_manager.consume_seed! }.not_to(change { user.reload.seed_count })
        expect(seed_manager.consume_seed!).to be false
      end
    end
  end

  describe "#current_count" do
    it "returns user seed count" do
      expect(seed_manager.current_count).to eq(3)
    end

    it "reflects real-time count after consumption" do
      seed_manager.consume_seed!
      expect(seed_manager.current_count).to eq(2)
    end
  end

  describe "#insufficient_seeds_message" do
    it "returns appropriate message" do
      expect(seed_manager.insufficient_seeds_message).to eq("タネが不足しているためTILは生成されませんでした")
    end
  end
end
