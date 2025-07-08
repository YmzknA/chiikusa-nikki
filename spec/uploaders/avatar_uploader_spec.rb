require "rails_helper"

RSpec.describe AvatarUploader do
  let(:user) { create(:user) }
  let(:uploader) { AvatarUploader.new(user, :avatar) }

  before do
    AvatarUploader.enable_processing = false
  end

  after do
    AvatarUploader.enable_processing = false
  end

  describe "#extension_allowlist" do
    it "returns allowed file extensions" do
      expect(uploader.extension_allowlist).to eq(%w[jpg jpeg gif png webp])
    end
  end

  describe "#content_type_allowlist" do
    it "returns allowed content types" do
      expect(uploader.content_type_allowlist).to eq(%w[image/jpeg image/gif image/png image/webp])
    end
  end

  describe "#filename" do
    context "when original filename is present" do
      before do
        allow(uploader).to receive(:original_filename).and_return("test.jpg")
      end

      it "returns secure filename" do
        expect(uploader.filename).to match(/^avatar_[a-f0-9]{20}\.jpg$/)
      end
    end

    context "when original filename is not present" do
      before do
        allow(uploader).to receive(:original_filename).and_return(nil)
      end

      it "returns nil" do
        expect(uploader.filename).to be_nil
      end
    end
  end

  describe "#size_range" do
    it "returns size range from 1 byte to 5 megabytes" do
      expect(uploader.size_range).to eq((1.byte)..(5.megabytes))
    end
  end

  describe "#check_file_type!" do
    context "when file is not present" do
      it "does not raise error" do
        expect { uploader.send(:check_file_type!) }.not_to raise_error
      end
    end

    context "when file is present" do
      let(:mock_file) { double("file") }

      before do
        uploader.instance_variable_set(:@file, mock_file)
      end

      context "with valid JPEG file" do
        it "does not raise error" do
          allow(mock_file).to receive(:read).with(8).and_return("\xFF\xD8\xFF\xE0test")
          allow(mock_file).to receive(:rewind)
          allow(mock_file).to receive(:present?).and_return(true)

          expect { uploader.send(:check_file_type!) }.not_to raise_error
        end
      end

      context "with valid PNG file" do
        it "does not raise error" do
          allow(mock_file).to receive(:read).with(8).and_return("\x89PNG\r\n\x1A\ntest")
          allow(mock_file).to receive(:rewind)
          allow(mock_file).to receive(:present?).and_return(true)

          expect { uploader.send(:check_file_type!) }.not_to raise_error
        end
      end

      context "with invalid file type" do
        it "raises CarrierWave::IntegrityError" do
          allow(mock_file).to receive(:read).with(8).and_return("INVALID_CONTENT")
          allow(mock_file).to receive(:rewind)
          allow(mock_file).to receive(:present?).and_return(true)

          expect do
            uploader.send(:check_file_type!)
          end.to raise_error(CarrierWave::IntegrityError, "不正なファイル形式です")
        end
      end
    end
  end
end
