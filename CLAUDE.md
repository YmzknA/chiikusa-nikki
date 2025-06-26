# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際のClaude Code (claude.ai/code) 向けガイダンスです。

## 開発コマンド

### アプリケーション起動
- `bin/dev` - 開発サーバーをCSS・JSのホットリロードと共に起動
- `docker compose up` - PostgreSQLを含む完全なアプリケーションをDockerで起動
- `bin/rails server` - Railsサーバーのみ起動（別途データベースが必要）

### テスト実行
- `bin/rails test` - 全てのテスト（ユニット・システムテスト）を実行
- `bin/rails test:system` - システムテストのみ実行
- `bin/rspec` - RSpecテストを実行（メインのテストフレームワーク）
- `bin/rspec spec/models/` - モデルテストのみ実行
- `bin/rspec spec/requests/` - リクエスト/コントローラーテストのみ実行

### コード品質・セキュリティ
- `bin/rubocop` - Rubyリンター（スタイル・フォーマット）を実行
- `bin/brakeman` - セキュリティ脆弱性スキャナーを実行
- `bin/rails db:test:prepare` - テストデータベースを準備（テスト前に実行）

### アセットビルド
- `yarn build` - JavaScriptアセットをビルド
- `yarn build:css` - TailwindでCSSをビルド
- `yarn build --watch` - JSアセットを監視して自動リビルド
- `yarn build:css --watch` - CSSを監視して自動リビルド

### データベース
- `bin/rails db:create` - データベースを作成
- `bin/rails db:migrate` - データベースマイグレーションを実行
- `bin/rails db:seed` - 初期データをシード
- `bin/rails db:reset` - データベースをドロップ・作成・マイグレート・シード

## アプリケーション概要

### コアコンセプト
プログラミング学習初級者向けの日記アプリケーション「Programming Diary」。AIによるTIL生成機能とGitHub連携を持つ。

**世界観・UI特徴:**
- 雑草キャラクターをマスコット的に使用
- 日記を付けるたびに雑草が水をもらって喜ぶ演出
- GitHubの草機能のような雑草表示システム
- 気分に応じて雑草の顔が変化

### 主要モデル構成
- `User` - GitHub OAuth認証ユーザー
- `Diary` - 日記エントリー（メモとAI生成TIL）
- `Question`/`Answer`/`DiaryAnswer` - 気分・モチベーション・進捗の5段階評価システム
- `TilCandidate` - OpenAIが生成したTIL候補（3つ）
- `DailyWeather` - 天気データ（JSONB形式）

**外部サービス:**
- `OpenaiService` - GPT-4-nanoを使用して日記メモからTIL候補を生成
- `GithubService` - 選択されたTILをユーザーのGitHubリポジトリにプッシュ

### フロントエンド技術
- **CSSフレームワーク:** Tailwind CSS 4.x
- **JavaScript:** Stimulus controllers + Hotwire/Turbo
- **ビルドツール:** esbuild（JavaScript）、Tailwind CLI（CSS）
- **グラフ表示:** Chart.js + stimulus-chartjsで統計の可視化

### 認証・外部連携
- **OAuth:** GitHub OAuthによるユーザー認証（OmniAuth使用）
- **GitHub API:** Octokit gemでリポジトリ操作（TIL公開）
- **OpenAI API:** GPT-4-nanoモデルで日記メモからTIL生成
- **X（Twitter）:** Web Intentを使用した投稿機能

## 主要機能

### 日記機能の流れ
1. **5段階評価入力** - 気分（😞〜😄）、モチベーション（🧊〜🔥）、進捗（✖️〜✅）
2. **箇条書きメモ入力** - 自由記述での学習記録
3. **AI TIL生成** - OpenAIがメモから3つのTIL候補を自動生成
4. **TIL選択** - ユーザーが好みのTILを1つ選択
5. **外部連携** - GitHub Push機能、X投稿機能

### 統計・可視化
- 直近30日間の記録をChart.jsでグラフ表示
- 気分・モチベーション・進捗の推移を可視化
- 雑草カレンダー表示（simple_calendarを使用）

### データベース構造の特徴
- Usersは複数のdiariesを持つ
- Diariesは複数のdiary_answersとtil_candidatesを持つ
- Questions/Answersは事前定義された評価システム
- DiaryAnswersで日記と質問回答を関連付け

## テスト戦略
- **RSpec** - ユニットテストと統合テスト
- **Capybara + Selenium** - システムテスト
- **Shoulda Matchers** - モデルバリデーションテスト
- モデル、コントローラー、リクエスト、フルシステムワークフローをカバー

## 開発環境
- **Docker** - compose.ymlでフルスタック開発サポート
- **Rails Credentials** - APIキー管理（GitHub、OpenAI）
- **環境変数** - Docker開発用のトークン設定

## 重要な注意事項

### 外部API依存関係
以下の有効なAPI認証情報が必要:
- GitHub OAuth（client_id, client_secret）
- OpenAI API（GPT-4-nano用のapi_key）

### TILワークフロー
1. ユーザーがメモ付きで日記エントリーを作成
2. OpenAIが3つのTIL候補をメモから生成
3. 編集ページでユーザーが好みのTILを選択
4. オプション: 選択したTILをMarkdownファイルとしてGitHubリポジトリにプッシュ

### 雑草機能
- `simple_calendar` gemを使用したカレンダー表示
- 日記エントリーに対する視覚的インジケーター
- 気分に応じた雑草の表情変化システム