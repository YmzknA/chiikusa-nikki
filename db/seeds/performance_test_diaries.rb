# パフォーマンステスト用：100件の日記とリアクションデータを生成するシード
# 使用方法: rails db:seed:replant FILTER=performance_test_diaries

unless Rails.env.development?
  puts "⚠️  このシードは開発環境でのみ実行できます"
  exit
end

puts "🌱 パフォーマンステスト用の日記データを生成中..."

# 既存のテストユーザーを取得または作成
test_user = User.find_or_create_by!(email: "test@example.com") do |user|
  user.username = "テストユーザー"
  user.github_id = "test123"
  user.avatar = "https://via.placeholder.com/150"
  user.seed_count = 5  # 種を満タンに
  user.providers = ["github"]
end

# 追加テストユーザー（リアクション用）
reaction_users = []
5.times do |i|
  reaction_users << User.find_or_create_by!(email: "reaction_user_#{i}@example.com") do |user|
    user.username = "リアクションユーザー#{i + 1}"
    user.github_id = "reaction_#{i}"
    user.avatar = "https://via.placeholder.com/150"
    user.providers = ["github"]
  end
end

# 質問と回答データの準備
questions = Question.all
if questions.empty?
  puts "⚠️  Question データが存在しません。先にメインシードを実行してください。"
  exit
end

# プライベートメソッド定義を先に配置
def generate_notes(index)
  notes_templates = [
    "今日はRuby on Railsの勉強をしました。ActiveRecordの使い方について学び、N+1問題の解決方法を理解しました。",
    "JavaScriptのPromiseとasync/awaitについて学習しました。非同期処理の理解が深まった気がします。",
    "SQLの結合クエリ（JOIN）について復習しました。INNER JOIN、LEFT JOIN、RIGHT JOINの違いが分かってきました。",
    "Gitのブランチ戦略について調べました。Git FlowとGitHub Flowの違いについて整理しました。",
    "CSSのFlexboxレイアウトについて実装練習をしました。justify-contentとalign-itemsの使い分けをマスターしたい。",
    "Dockerの基本的な使い方を学びました。コンテナの作成、実行、削除の流れを理解しました。",
    "テスト駆動開発(TDD)について学習しました。RSpecを使ったテストの書き方を練習しました。",
    "API設計について勉強しました。RESTfulなAPIの設計原則について理解を深めました。",
    "データベース設計の正規化について学習しました。第1〜第3正規形の違いについて整理しました。",
    "セキュリティについて学びました。SQLインジェクションやXSS攻撃の対策方法を調べました。"
  ]
  
  base_note = notes_templates[index % notes_templates.length]
  "#{base_note}\n\n追加メモ#{index + 1}: #{Time.current.strftime('%Y-%m-%d')}の学習記録として残しておきます。"
end

def generate_til_text(index)
  til_templates = [
    "Active Recordのincludesメソッドを使うことで、N+1問題を効率的に解決できることがわかりました。",
    "JavaScriptのPromise.allを使うことで、複数の非同期処理を並列実行できることを学びました。",
    "SQLのEXPLAIN文を使うことで、クエリの実行計画を確認してパフォーマンスを最適化できることがわかりました。",
    "Gitのrebaseコマンドを使うことで、コミット履歴をきれいに整理できることを学びました。",
    "CSS GridとFlexboxを組み合わせることで、より柔軟なレイアウトが実現できることがわかりました。",
    "Dockerのマルチステージビルドを使うことで、本番用イメージのサイズを大幅に削減できることを学びました。",
    "RSpecのletメソッドを使うことで、テストデータの準備を効率的に行えることがわかりました。",
    "REST APIの設計では、リソース指向の考え方が重要であることを理解しました。",
    "データベースのインデックスを適切に設定することで、クエリのパフォーマンスが劇的に改善されることを学びました。",
    "CSRFトークンを使用することで、クロスサイトリクエストフォージェリ攻撃を防げることがわかりました。"
  ]
  
  til_templates[index % til_templates.length]
end

def generate_til_candidate(diary_index, candidate_index)
  base_contents = [
    ["Active RecordのincludesでN+1問題を解決する方法", "Joinクエリを使った効率的なデータ取得", "バッチ処理でのメモリ使用量最適化"],
    ["Promiseチェーンの書き方と非同期処理", "async/await構文の使い方", "エラーハンドリングのベストプラクティス"],
    ["SQLクエリのパフォーマンス最適化手法", "インデックス設計の考え方", "EXPLAIN文での実行計画確認"],
    ["Gitワークフローの選択と運用方法", "コンフリクト解決のテクニック", "コミットメッセージの書き方"],
    ["レスポンシブデザインの実装方法", "モバイルファーストの設計思想", "CSSの保守性を高める設計"],
    ["コンテナオーケストレーションの基礎", "Docker Composeの活用方法", "本番環境でのコンテナ運用"],
    ["テスト設計の基本原則", "モックとスタブの使い分け", "テストカバレッジの考え方"],
    ["API仕様書の書き方とOpenAPI", "バージョニング戦略", "エラーレスポンスの設計"],
    ["正規化の段階的な進め方", "パフォーマンスと正規化のトレードオフ", "NoSQLとRDBMSの使い分け"],
    ["セキュリティ脆弱性の種類と対策", "認証と認可の違い", "暗号化技術の基礎知識"]
  ]
  
  content_group = base_contents[diary_index % base_contents.length]
  content_group[candidate_index]
end

# 100件の日記を生成（過去3ヶ月分）
start_date = 3.months.ago.to_date
diaries_created = 0

puts "📝 日記を生成中..."
100.times do |i|
  date = start_date + i.days
  
  # 重複チェック
  next if Diary.exists?(user: test_user, date: date)
  
  diary = Diary.create!(
    user: test_user,
    date: date,
    notes: generate_notes(i),
    til_text: generate_til_text(i),
    selected_til_index: rand(0..2),
    is_public: [true, false].sample, # 50%の確率で公開
    github_uploaded: [true, false].sample, # 50%の確率でGitHubアップロード済み
    created_at: date.beginning_of_day + rand(8..22).hours,
    updated_at: date.beginning_of_day + rand(8..22).hours
  )
  
  # 日記回答を生成（気分、モチベーション、進捗）
  questions.each do |question|
    answer = question.answers.sample
    DiaryAnswer.create!(
      diary: diary,
      question: question,
      answer: answer
    )
  end
  
  # TIL候補を3つ生成
  3.times do |til_index|
    TilCandidate.create!(
      diary: diary,
      index: til_index,
      content: generate_til_candidate(i, til_index)
    )
  end
  
  # リアクションをランダム生成（パフォーマンステスト用に多めに）
  if diary.is_public?
    # 各日記に5-15個のリアクションを付与
    reaction_count = rand(5..15)
    emojis = Reaction::EMOJI_CATEGORIES.values.flat_map { |cat| cat[:emojis] }
    
    reaction_count.times do
      emoji = emojis.sample
      user = reaction_users.sample
      
      # 重複チェック
      unless Reaction.exists?(diary: diary, user: user, emoji: emoji)
        Reaction.create!(
          diary: diary,
          user: user,
          emoji: emoji
        )
      end
    end
  end
  
  diaries_created += 1
  
  # 進捗表示
  if (i + 1) % 10 == 0
    puts "  ✅ #{i + 1}/100 日記作成完了"
  end
end

# 統計情報を表示
puts "\n📊 生成データ統計:"
puts "  👤 ユーザー: #{User.count}人"
puts "  📝 日記: #{test_user.diaries.count}件 (うち新規作成: #{diaries_created}件)"
puts "  🌟 リアクション: #{Reaction.joins(:diary).where(diary: { user: test_user }).count}件"
puts "  📅 日付範囲: #{test_user.diaries.minimum(:date)} 〜 #{test_user.diaries.maximum(:date)}"
puts "  🌍 公開日記: #{test_user.diaries.where(is_public: true).count}件"

puts "\n🚀 パフォーマンステストの準備が完了しました！"
puts "   ログイン情報: test@example.com"

