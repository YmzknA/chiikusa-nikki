require 'rails_helper'

RSpec.describe TilCandidate, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:diary) }
  end
end
