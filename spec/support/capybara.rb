# 2024年最新のCapybara + Selenium設定
# webdrivers gemは非推奨 - Selenium 4が自動でChromeDriverを管理

# Capybara設定
Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.default_normalize_ws = true
  config.default_set_options = { clear: :backspace }
  config.enable_aria_label = true
end

# Chrome Optionsの設定（Docker環境対応）
def create_chrome_options
  chrome_options = Selenium::WebDriver::Chrome::Options.new

  # 基本オプション
  chrome_options.add_argument("--headless=new")  # 新しいヘッドレスモード
  chrome_options.add_argument("--no-sandbox")    # Docker環境では必須
  chrome_options.add_argument("--disable-dev-shm-usage") # メモリ不足対策
  chrome_options.add_argument("--disable-gpu") # GPU無効化
  chrome_options.add_argument("--disable-web-security")
  chrome_options.add_argument("--allow-running-insecure-content")
  chrome_options.add_argument("--disable-extensions")
  chrome_options.add_argument("--disable-plugins")
  chrome_options.add_argument("--disable-images")
  chrome_options.add_argument("--disable-background-timer-throttling")
  chrome_options.add_argument("--disable-backgrounding-occluded-windows")
  chrome_options.add_argument("--disable-renderer-backgrounding")

  # セッション競合回避のためのユニークなユーザーデータディレクトリ
  user_data_dir = "/tmp/chrome_#{Time.now.to_f}_#{rand(10_000)}"
  chrome_options.add_argument("--user-data-dir=#{user_data_dir}")

  # ウィンドウサイズ設定
  chrome_options.add_argument("--window-size=1400,1400")

  # Chrome binary設定（Docker環境）
  chrome_binary = ENV["CHROME_BINARY"] || "/usr/bin/google-chrome"
  chrome_options.binary = chrome_binary if File.exist?(chrome_binary)

  chrome_options
end

# カスタムドライバーの登録
Capybara.register_driver :selenium_chrome_headless do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: create_chrome_options
  )
end

# 従来のheadless_chromeとの互換性のため
Capybara.register_driver :headless_chrome do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: create_chrome_options
  )
end

# rack_test用の設定（非JSテスト）
Capybara.register_driver :rack_test do |app|
  Capybara::RackTest::Driver.new(app, headers: {
                                   "HTTP_USER_AGENT" => "Capybara"
                                 })
end

RSpec.configure do |config|
  # デフォルトドライバー（非JSテスト）
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  # JSが必要なテスト用
  config.before(:each, :js, type: :system) do
    driven_by :selenium_chrome_headless
  end

  # テスト後のクリーンアップ
  config.after(:each, type: :system) do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  # システムテスト用の追加設定
  config.before(:each, type: :system) do |example|
    # レスポンシブテスト用のビューポート設定（JS有効時のみ）
    if example.metadata[:mobile] && page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:manage)
      page.driver.browser.manage.window.resize_to(375, 667)
    elsif example.metadata[:tablet] && page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:manage)
      page.driver.browser.manage.window.resize_to(768, 1024)
    end
  end

  # System test authentication helper
  config.include AuthenticationHelpers, type: :system
end

# デバッグ用設定（開発時のみ）
if ENV["DEBUG_CAPYBARA"]
  Capybara.configure do |config|
    config.save_path = Rails.root.join("tmp/capybara")
    config.automatic_screenshot_path = Rails.root.join("tmp/capybara")
  end
end
