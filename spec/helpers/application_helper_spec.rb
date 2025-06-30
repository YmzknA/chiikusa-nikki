require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#hide_navigation?" do
    context "when on home index page" do
      before do
        allow(helper).to receive(:controller_name).and_return("home")
        allow(helper).to receive(:action_name).and_return("index")
      end

      it "returns true" do
        expect(helper.hide_navigation?).to be true
      end
    end

    context "when on users setup_username page" do
      before do
        allow(helper).to receive(:controller_name).and_return("users")
        allow(helper).to receive(:action_name).and_return("setup_username")
      end

      it "returns true" do
        expect(helper.hide_navigation?).to be true
      end
    end

    context "when on other pages" do
      before do
        allow(helper).to receive(:controller_name).and_return("diaries")
        allow(helper).to receive(:action_name).and_return("index")
      end

      it "returns false" do
        expect(helper.hide_navigation?).to be false
      end
    end

    context "when on profiles page" do
      before do
        allow(helper).to receive(:controller_name).and_return("profiles")
        allow(helper).to receive(:action_name).and_return("show")
      end

      it "returns false" do
        expect(helper.hide_navigation?).to be false
      end
    end
  end
end
