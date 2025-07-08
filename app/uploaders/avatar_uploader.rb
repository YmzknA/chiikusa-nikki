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
    magic_number = file.read(12)  # WebP検証のために12バイト読み取り
    file.rewind

    return if valid_file_format?(magic_number)

    raise CarrierWave::IntegrityError, I18n.t('avatar_security.invalid_file_type')
  end

  def valid_file_format?(magic_number)
    return true if magic_number.start_with?("\xFF\xD8\xFF")           # JPEG
    return true if magic_number.start_with?("\x89PNG\r\n\x1A\n")      # PNG
    return true if magic_number.start_with?("GIF8")                   # GIF
    return true if webp_valid?(magic_number)                          # WebP

    false
  end

  def webp_valid?(magic_number)
    return false unless magic_number.start_with?("RIFF")
    return false unless magic_number.length >= 12
    
    # WebPファイルの'WEBP'シグネチャ確認
    magic_number[8..11] == "WEBP"
  end

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.hex(10))
  end
end
