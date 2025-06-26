require "rails_helper"

RSpec.describe Question, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:answers) }
  end
end
