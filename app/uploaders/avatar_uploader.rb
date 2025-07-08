class AvatarUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave

  # Process files as they are uploaded:
  process :resize_to_fill => [150, 150]
  process :convert => 'jpg'

  # Add an allowlist of extensions which are allowed to be uploaded.
  def extension_allowlist
    %w(jpg jpeg gif png webp)
  end

  # Override the filename of the uploaded files to remove location data:
  def filename
    "avatar_#{secure_token}.jpg" if original_filename.present?
  end

  # Add file size validation
  def size_range
    1.byte..5.megabytes
  end

  private

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.hex(10))
  end
end
