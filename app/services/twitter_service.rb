require 'twitter'

class TwitterService
  def initialize
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV.fetch("TWITTER_API_KEY")
      config.consumer_secret     = ENV.fetch("TWITTER_API_SECRET_KEY")
      config.access_token        = ENV.fetch("TWITTER_ACCESS_TOKEN")
      config.access_token_secret = ENV.fetch("TWITTER_ACCESS_TOKEN_SECRET")
    end
  end

  def post_til(til_text)
    @client.update(til_text)
  end
end
