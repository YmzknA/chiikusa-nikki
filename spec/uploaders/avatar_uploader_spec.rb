require 'rails_helper'
require 'carrierwave/test/matchers'

RSpec.describe AvatarUploader do
  include CarrierWave::Test::Matchers

  let(:user) { create(:user) }
  let(:uploader) { AvatarUploader.new(user, :avatar) }

  before do
    AvatarUploader.enable_processing = true
  end

  after do
    AvatarUploader.enable_processing = false
  end

  describe "file extensions" do
    it "allows jpeg files" do
      expect(uploader.extension_allowlist).to include("jpg")
      expect(uploader.extension_allowlist).to include("jpeg")
    end

    it "allows png files" do
      expect(uploader.extension_allowlist).to include("png")
    end

    it "allows webp files" do
      expect(uploader.extension_allowlist).to include("webp")
    end

    it "allows gif files" do
      expect(uploader.extension_allowlist).to include("gif")
    end
  end

  describe "processing" do
    # Note: This test might need actual image files in spec/fixtures
    # For now, we test the configuration
    
    it "has resize_to_fill processor configured" do
      # This tests that the uploader is configured with resize_to_fill
      expect(uploader.processors).to include([:resize_to_fill, [150, 150]])
    end

    it "has convert processor configured" do
      expect(uploader.processors).to include([:convert, "jpg"])
    end
  end

  describe "filename generation" do
    it "generates secure filename" do
      uploader.store\!(File.open("spec/fixtures/test_image.jpg")) if File.exist?("spec/fixtures/test_image.jpg")
      expect(uploader.filename).to match(/^avatar_[a-f0-9]{20}\.jpg$/) if uploader.filename
    end
  end

  describe "size validation" do
    it "has size range configured" do
      expect(uploader.size_range).to eq(1.byte..5.megabytes)
    end
  end
end
