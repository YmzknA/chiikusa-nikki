class OpenaiService
  def initialize
    # Set the environment variable for OpenAI client
    ENV['OPENAI_API_KEY'] = Rails.application.credentials.dig(:openai, :api_key)
    @client = OpenAI::Client.new
  end

  def generate_til(notes)
    # 学習記録に基づいてTILを生成（一時的にフォールバック版を使用）
    return generate_smart_tils(notes) if notes.present?
    generate_fallback_tils
  rescue => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    generate_fallback_tils
  end

  private

  def generate_smart_tils(notes)
    # 学習ノートから関連するキーワードを抽出してTILを生成
    keywords = extract_keywords(notes)
    actions = extract_actions(notes)
    
    tils = []
    
    if keywords.any?
      # より自然なTIL文章を生成
      selected_keywords = keywords.sample(3)
      selected_keywords.each_with_index do |keyword, index|
        case index % 3
        when 0
          tils << "今日は#{keyword}について学びました！#{actions.sample || '新しい発見がありました'}。"
        when 1
          tils << "#{keyword}の使い方が理解できました。実践的な知識が身につきました。"
        when 2
          tils << "#{keyword}を活用した#{actions.sample || '実装'}ができました。"
        end
      end
    else
      tils = generate_fallback_tils
    end
    
    # 足りない場合は補完
    while tils.length < 3
      tils << generate_generic_til(notes)
    end
    
    tils.first(3)
  end

  def extract_keywords(notes)
    # 簡単なキーワード抽出（プログラミング関連）
    programming_terms = %w[
      Rails Ruby JavaScript CSS HTML React Vue Angular
      Python Java C++ PHP Go Rust Swift Kotlin
      Git GitHub Docker Kubernetes AWS GCP Azure
      SQL PostgreSQL MySQL MongoDB Redis
      API REST GraphQL JSON XML
      Bootstrap Tailwind SCSS Sass
      jQuery Node.js Express Laravel Django Flask
      Vue.js Angular.js TypeScript
      データベース フロントエンド バックエンド
      フレームワーク ライブラリ アルゴリズム
      デバッグ テスト 設計 リファクタリング
    ]
    
    found_terms = programming_terms.select do |term|
      notes.include?(term) || notes.include?(term.downcase)
    end
    
    # 日本語のプログラミング用語も検索
    japanese_terms = notes.scan(/(フォーム|ボタン|スタイル|コンポーネント|モデル|ビュー|コントローラー|API|データベース|認証|ログイン|エラー|バグ|機能|実装|修正|追加|更新|削除|作成|設計|テスト|デプロイ)/)
    
    (found_terms + japanese_terms.flatten).uniq
  end

  def extract_actions(notes)
    # アクション/動作を表す語句を抽出
    actions = notes.scan(/(作成|実装|修正|追加|更新|削除|設計|テスト|デプロイ|学習|理解|習得|練習|挑戦|完了|解決|改善|最適化)/)
    actions.flatten.uniq
  end

  def generate_generic_til(notes)
    # ノートの長さに基づいてジェネリックなTILを生成
    if notes.length > 100
      "今日はたくさんのことを学習できました。継続が力になります！"
    elsif notes.length > 50
      "新しい技術に挑戦することができました。"
    else
      "プログラミング学習を継続できました。"
    end
  end

  def generate_fallback_tils
    [
      "今日は新しいことを学びました！",
      "プログラミングの理解が深まりました。",
      "継続して学習を進めることができました。"
    ]
  end
end
