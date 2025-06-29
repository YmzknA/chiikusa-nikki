require "rails_helper"

RSpec.describe SeedService, type: :service do
  let(:user) { create(:user, seed_count: 3) }
  let(:service) { described_class.new(user) }

  describe "#initialize" do
    it "sets user and initializes attributes" do
      expect(service.user).to eq(user)
      expect(service.success).to be_nil
      expect(service.message).to be_nil
    end
  end

  describe "#increment_daily_seed" do
    context "when conditions are met" do
      it "increments seed count successfully" do
        expect do
          result = service.increment_daily_seed
          expect(result).to eq(service)
        end.to change { user.reload.seed_count }.by(1)

        expect(service.success).to be true
        expect(service.message).to eq("タネを増やしました！💧🌱")
        expect(user.last_seed_incremented_at.to_date).to eq(Date.current)
      end

      it "updates last_seed_incremented_at timestamp" do
        time_before = Time.current
        service.increment_daily_seed
        expect(user.reload.last_seed_incremented_at).to be >= time_before
      end
    end

    context "when already incremented today" do
      before do
        user.update!(last_seed_incremented_at: Time.current)
      end

      it "does not increment and returns failure" do
        expect do
          result = service.increment_daily_seed
          expect(result).to eq(service)
        end.not_to(change { user.reload.seed_count })

        expect(service.success).to be false
        expect(service.message).to eq("本日は既にタネを増やしています。")
      end
    end

    context "when seed count is at maximum" do
      before do
        user.update!(seed_count: 5)
      end

      it "does not increment and returns failure" do
        expect do
          result = service.increment_daily_seed
          expect(result).to eq(service)
        end.not_to(change { user.reload.seed_count })

        expect(service.success).to be false
        expect(service.message).to eq("本日は既にタネを増やしています。")
      end
    end

    context "when user has incremented yesterday" do
      before do
        user.update!(last_seed_incremented_at: 1.day.ago)
      end

      it "allows increment for new day" do
        expect do
          service.increment_daily_seed
        end.to change { user.reload.seed_count }.by(1)

        expect(service.success).to be true
      end
    end

    context "when seed count is 4 (one below maximum)" do
      before do
        user.update!(seed_count: 4)
      end

      it "increments to maximum" do
        expect do
          service.increment_daily_seed
        end.to change { user.reload.seed_count }.from(4).to(5)

        expect(service.success).to be true
      end
    end
  end

  describe "#increment_share_seed" do
    context "when conditions are met" do
      it "increments seed count successfully" do
        expect do
          result = service.increment_share_seed
          expect(result).to eq(service)
        end.to change { user.reload.seed_count }.by(1)

        expect(service.success).to be true
        expect(service.message).to eq("Xで共有してタネを増やしました！")
        expect(user.reload.last_shared_at.to_date).to eq(Date.current)
      end

      it "updates last_shared_at timestamp" do
        time_before = Time.current
        service.increment_share_seed
        expect(user.reload.last_shared_at).to be >= time_before
      end
    end

    context "when already shared today" do
      before do
        user.update!(last_shared_at: Time.current)
      end

      it "does not increment and returns failure" do
        expect do
          result = service.increment_share_seed
          expect(result).to eq(service)
        end.not_to(change { user.reload.seed_count })

        expect(service.success).to be false
        expect(service.message).to eq("本日は既にX共有でタネを増やしています。")
      end
    end

    context "when seed count is at maximum" do
      before do
        user.update!(seed_count: 5)
      end

      it "does not increment and returns failure" do
        expect do
          result = service.increment_share_seed
          expect(result).to eq(service)
        end.not_to(change { user.reload.seed_count })

        expect(service.success).to be false
        expect(service.message).to eq("本日は既にX共有でタネを増やしています。")
      end
    end

    context "when user shared yesterday" do
      before do
        user.update!(last_shared_at: 1.day.ago)
      end

      it "allows increment for new day" do
        expect do
          service.increment_share_seed
        end.to change { user.reload.seed_count }.by(1)

        expect(service.success).to be true
      end
    end

    context "when both watering and sharing limits are reached" do
      before do
        user.update!(
          last_seed_incremented_at: Time.current,
          last_shared_at: Time.current
        )
      end

      it "respects share-specific limits" do
        expect do
          service.increment_share_seed
        end.not_to(change { user.reload.seed_count })

        expect(service.success).to be false
        expect(service.message).to include("X共有で")
      end
    end
  end

  describe "#html_message_for_increment" do
    context "when increment was successful" do
      before do
        service.increment_daily_seed
      end

      it "returns simplified success message" do
        expect(service.html_message_for_increment).to eq("タネを増やしました！")
      end
    end

    context "when increment failed" do
      before do
        user.update!(last_seed_incremented_at: Time.current)
        service.increment_daily_seed
      end

      it "returns full failure message" do
        expect(service.html_message_for_increment).to eq("本日は既にタネを増やしています。")
      end
    end

    context "when service has not been called yet" do
      it "returns nil" do
        expect(service.html_message_for_increment).to be_nil
      end
    end
  end

  describe "#html_message_for_share" do
    context "when share increment was successful" do
      before do
        service.increment_share_seed
      end

      it "returns share success message" do
        expect(service.html_message_for_share).to eq("Xで共有してタネを増やしました！")
      end
    end

    context "when share increment failed" do
      before do
        user.update!(last_shared_at: Time.current)
        service.increment_share_seed
      end

      it "returns share failure message" do
        expect(service.html_message_for_share).to eq("本日は既にX共有でタネを増やしています。")
      end
    end

    context "when service has not been called yet" do
      it "returns nil" do
        expect(service.html_message_for_share).to be_nil
      end
    end
  end

  describe "service chaining" do
    it "returns self for method chaining" do
      result = service.increment_daily_seed
      expect(result).to eq(service)
      expect(result.success).to be_truthy
      expect(result.message).to be_present
    end

    it "allows accessing attributes after chaining" do
      result = service.increment_share_seed
      expect(result.user).to eq(user)
      expect(result.success).to be_truthy
    end
  end

  describe "edge cases and error handling" do
    context "when user model validation fails" do
      before do
        # Mock a validation failure
        allow(user).to receive(:add_seed_from_watering!).and_return(false)
      end

      it "handles validation failures gracefully" do
        expect do
          service.increment_daily_seed
        end.not_to raise_error

        expect(service.success).to be false
      end
    end

    context "when database transaction fails" do
      before do
        allow(user).to receive(:add_seed_from_sharing!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "does not suppress database errors" do
        expect do
          service.increment_share_seed
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "timezone handling" do
    context "in different timezone" do
      around do |example|
        Time.use_zone("Asia/Tokyo") do
          example.run
        end
      end

      it "respects current timezone for daily limits" do
        # Set increment time to yesterday in current timezone
        user.update!(last_seed_incremented_at: 1.day.ago.in_time_zone)

        expect do
          service.increment_daily_seed
        end.to change { user.reload.seed_count }.by(1)

        expect(service.success).to be true
      end
    end
  end

  describe "attribute readers" do
    it "exposes user as readable attribute" do
      expect(service).to respond_to(:user)
      expect(service.user).to eq(user)
    end

    it "exposes success as readable attribute" do
      expect(service).to respond_to(:success)
    end

    it "exposes message as readable attribute" do
      expect(service).to respond_to(:message)
    end
  end
end
