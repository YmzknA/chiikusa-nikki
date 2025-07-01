# Be sure to restart your server when you modify this file.

# Define an application-wide HTTP permissions policy. For further
# information see: https://developers.google.com/web/updates/2018/06/feature-policy

Rails.application.config.permissions_policy do |policy|
  # Railsがサポートしている主要なディレクティブのみを使用

  # カメラアクセスを完全に無効化
  policy.camera      :none

  # ジャイロスコープアクセスを完全に無効化
  policy.gyroscope   :none

  # マイクアクセスを完全に無効化
  policy.microphone  :none

  # USBデバイスアクセスを完全に無効化
  policy.usb         :none

  # フルスクリーンAPIは自分のオリジンのみ許可
  policy.fullscreen  :self

  # 決済APIは使用しないため無効化
  policy.payment     :none

  # 位置情報アクセスを完全に無効化
  policy.geolocation :none

  # 自動再生を無効化
  policy.autoplay :none

  # MIDI APIを無効化
  policy.midi :none

  # Picture-in-Picture機能を無効化
  policy.picture_in_picture :none

  # 暗号化メディア拡張を無効化（encrypted-mediaが正しい名前）
  policy.encrypted_media :none
end
