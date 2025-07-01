# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# CSP基本設定のモジュール
module ContentSecurityPolicyConfig
  def self.setup_basic_sources(policy)
    policy.default_src :self
    policy.font_src :self, :data, "https://fonts.gstatic.com"
    policy.img_src :self, :data, :https
    policy.object_src :none
  end

  def self.setup_script_and_style(policy)
    # TODO: unsafe-inlineは段階的に削除し、すべてStimulusコントローラーに移行する
    policy.script_src :self, :unsafe_inline, "https://apis.google.com"
    policy.style_src :self, :unsafe_inline, "https://fonts.googleapis.com"
  end

  def self.setup_connections_and_forms(policy)
    policy.connect_src :self, "https://api.github.com", "https://api.openai.com",
                       "https://apis.google.com", "https://accounts.google.com", "wss:"
    policy.form_action :self, "https://github.com", "https://accounts.google.com"
  end

  def self.setup_security_restrictions(policy)
    policy.frame_ancestors :none
    policy.frame_src :none
    policy.media_src :none
    policy.worker_src :self
    policy.manifest_src :self
    policy.base_uri :self
    policy.report_uri "/csp-violation-report"
  end
end

Rails.application.configure do
  config.content_security_policy do |policy|
    ContentSecurityPolicyConfig.setup_basic_sources(policy)
    ContentSecurityPolicyConfig.setup_script_and_style(policy)
    ContentSecurityPolicyConfig.setup_connections_and_forms(policy)
    ContentSecurityPolicyConfig.setup_security_restrictions(policy)
  end

  # 開発環境では違反をレポートのみ（本番環境では強制）
  config.content_security_policy_report_only = Rails.env.development?
end
