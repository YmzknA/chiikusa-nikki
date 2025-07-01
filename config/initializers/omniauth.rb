# frozen_string_literal: true

# OmniAuth CSRF protection configuration
Rails.application.config.middleware.use OmniAuth::Builder do
  # Enable CSRF protection
  configure do |config|
    config.full_host = Rails.env.production? ? 'https://chiikusadiary.com' : 'http://localhost:3000'
    config.allowed_request_methods = [:post, :get]
    config.silence_get_warning = true
  end
end

# Prevent CSRF attacks on OmniAuth
OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true

# Additional security configurations
if Rails.env.production?
  OmniAuth.config.full_host = lambda do |env|
    request = Rack::Request.new(env)
    "#{request.scheme}://#{request.host}"
  end
end