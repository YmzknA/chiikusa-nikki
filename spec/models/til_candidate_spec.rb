require 'rails_helper'

RSpec.describe TilCandidate, type: :model do
  describe "associations" do
    it { should belong_to(:diary) }
  end
end
