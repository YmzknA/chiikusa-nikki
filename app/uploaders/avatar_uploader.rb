class AvatarUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave

  # Process files as they are uploaded:
  process resize_to_fill: [150, 150]
  process convert: "jpg"

  # Add an allowlist of extensions which are allowed to be uploaded.
  def extension_allowlist
    %w[jpg jpeg gif png webp]
  end

  # Add MIME type validation
  def content_type_allowlist
    %w[image/jpeg image/gif image/png image/webp]
  end

  # Check file integrity before processing
  def check_integrity!
    super
    check_file_type!
  end

  # Override the filename of the uploaded files to remove location data:
  def filename
    "avatar_#{secure_token}.jpg" if original_filename.present?
  end

  # Add file size validation
  def size_range
    (1.byte)..(5.megabytes)
  end

  private

  def check_file_type!
    return unless file.present?

    # マジックナンバーによる厳密なファイル形式検証
    magic_number = file.read(8)
    file.rewind

    valid_signatures = {
      "\xFF\xD8\xFF" => "jpeg",           # JPEG
      "\x89PNG\r\n\x1A\n" => "png",       # PNG
      "GIF8" => "gif",                    # GIF
      "RIFF" => "webp"                    # WebP
    }

    return if valid_signatures.any? { |sig, _| magic_number.start_with?(sig) }

    raise CarrierWave::IntegrityError, "不正なファイル形式です"
  end

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.hex(10))
  end
end
