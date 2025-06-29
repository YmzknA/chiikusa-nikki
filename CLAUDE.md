# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際のClaude Code (claude.ai/code) 向けガイダンスです。
YOLOモードで実行時も絶対にdocker内および、現在のディレクトリ以上に影響を与える行為は行わないでください。

必ず定期的にこのファイルを参照して、ルールを遵守した実装を行う。
基本的にdeep thikで行う。

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

### プルリク作成
- 部下として、上司に対してプルリクエストメッセージを作成するように
- 重要なプロジェクトであることを認識し、今後も長く運用できるようなものになる前提で
- work_log/　配下に本日の日付と実行日時で'+%y%m%d-%H%M_pr.md'形式の名前のファイルを作成し、実行

### コードレビュー
- 上司として、プロの自覚をもって実行
- 重要なプロジェクトであることを認識し、今後も長く運用できるようなものになる前提で
- 人間の可読性を重視し、長期保守運用に適した実装であるか確認
- SOLID原則、DRY原則にのっとったものであるかを確認する
- 特にセキュリティ的に問題がないか重視して確認する
- 指摘事項をpr.mdの下部に追加することで、修正者に分かりやすくチェックリストを作成する

## アプリケーション概要

### コアコンセプト
プログラミング学習初級者向けの日記アプリケーション「ちいくさ日記」。AIによるTIL生成機能とGitHub連携を持つ。

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

### フロントエンド実装ルール（Hotwireベース）
**今後の全ての実装は以下のHotwireベストプラクティスに従うこと:**

1. **Stimulusコントローラーの使用**: インタラクティブな機能は必ずStimulusコントローラーで実装
   - ファイルパス: `app/javascript/controllers/{名前}_controller.js`
   - 命名規則: kebab-caseでHTML属性、camelCaseでJavaScript
   - 例: `data-controller="water-effect"` → `WaterEffectController`

2. **宣言的なHTML**: データ属性を使用した機能の定義
   - `data-controller`: コントローラーの指定
   - `data-action`: イベントとアクションの結び付け
   - `data-{controller}-target`: DOM要素のターゲット指定
   - `data-{controller}-{name}-value`: 値の受け渡し

3. **Turbo Streamとの統合**: サーバーからの更新はTurbo Streamで処理
   - コントローラーからのJavaScript生成は避ける
   - DOM更新は`turbo_stream.update`、`turbo_stream.append`等を使用
   - フロントエンドでの受信は`Turbo.renderStreamMessage()`

4. **責任の分離**:
   - **HTML**: 構造とStimulus属性の定義のみ
   - **Stimulusコントローラー**: ユーザーインタラクション、DOM操作、API通信
   - **Railsコントローラー**: ビジネスロジック、データベース操作、レスポンス生成

5. **従来のJavaScript使用禁止**:
   - `addEventListener`による直接的なイベントリスナー登録禁止
   - `document.querySelector`による直接的なDOM操作禁止
   - fetchによる直接的なAPI呼び出しは極力避ける（Stimulusコントローラー内で管理）

6. **コントローラー登録**: 新しいStimulusコントローラーは`app/javascript/controllers/index.js`で登録

7. **デバッグとログ**: コンソールログでconnect、disconnect、アクション実行を記録

**実装例**:
```html
<!-- 良い例 -->
<div data-controller="modal" 
     data-modal-open-value="false">
  <button data-action="click->modal#open">開く</button>
  <div data-modal-target="content" class="hidden">...</div>
</div>
```

```javascript
// 良い例
export default class extends Controller {
  static targets = ["content"]
  static values = { open: Boolean }
  
  open() {
    this.contentTarget.classList.remove("hidden")
    this.openValue = true
  }
}
```

**避けるべき実装**:
```javascript
// 悪い例
document.addEventListener('DOMContentLoaded', function() {
  document.querySelector('.modal-button').addEventListener('click', ...)
})
```

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

## テスト戦略と実装方針

### 基本方針
- **RSpec** - ユニットテストと統合テスト（メインフレームワーク）
- **Capybara + Selenium** - 最小限のシステムテスト
- **Shoulda Matchers** - モデルバリデーションテスト
- **WebMock + VCR** - 外部API呼び出しの完全モック

### 🚨 外部API呼び出し禁止ルール（必須遵守）

#### 1. **実際のAPI呼び出し禁止**
```ruby
# ❌ 禁止 - 実際のAPI呼び出し
OpenAI::Client.new(access_token: "real_token").chat(...)
Octokit::Client.new(access_token: "real_token").create_contents(...)

# ✅ 推奨 - 完全モック
mock_client = instance_double(OpenAI::Client)
allow(OpenAI::Client).to receive(:new).and_return(mock_client)
allow(mock_client).to receive(:chat).and_return(mock_response)
```

#### 2. **WebMock必須化**
- 全テストで外部HTTP通信を完全ブロック
- `WebMock.disable_net_connect!(allow_localhost: true)`
- テスト実行時の外部サービス依存を排除

#### 3. **モック階層の明確化**
- **ユニットテスト**: クライアントレベルモック（`OpenAI::Client`, `Octokit::Client`）
- **統合テスト**: サービスレベルモック + WebMock
- **システムテスト**: 外部呼び出し完全ブロック + 基本UI確認のみ

#### 4. **allow_any_instance_of 使用禁止**
```ruby
# ❌ 禁止 - 予測不可能な動作
allow_any_instance_of(OpenaiService).to receive(:generate_tils)

# ✅ 推奨 - 明示的な依存注入
mock_service = instance_double(OpenaiService)
allow(controller).to receive(:openai_service).and_return(mock_service)
```

### テストレベル別ガイドライン

#### **ユニットテスト（Models, Services）**
- 目的: ビジネスロジックの検証
- 外部依存: 完全モック
- 実行頻度: 毎回のコード変更時
- 実行速度: 高速（< 1秒/テスト）

#### **統合テスト（Requests, Controllers）**
- 目的: コンポーネント間連携の検証
- 外部依存: WebMock + サービスレベルモック
- 実行頻度: PR作成時
- 実行速度: 中速（< 5秒/テスト）

#### **システムテスト（最小限）**
- 目的: 重要なUIフローの確認のみ
- 対象: ログイン、日記作成、基本ナビゲーション
- 外部依存: 完全ブロック
- 実行頻度: リリース前
- 実行速度: 低速（許容）

### 🎯 実用的テスト作成ルール

#### 1. **ローカル環境での完全動作**
- `bundle exec rspec` で全テスト成功
- Docker環境で安定動作
- CI/CD環境でも同様に動作

#### 2. **テストの保守性重視**
- 複雑すぎるテストは削除または簡素化
- パフォーマンステストは別途分離
- テスト実行時間の短縮を優先

#### 3. **モック設定のパターン化**
```ruby
# OpenAI API モックの標準パターン
before do
  stub_request(:post, /api\.openai\.com/)
    .to_return(
      status: 200,
      body: { choices: [{ message: { content: "Test TIL" } }] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end

# GitHub API モックの標準パターン  
before do
  mock_client = instance_double(Octokit::Client)
  allow(Octokit::Client).to receive(:new).and_return(mock_client)
  allow(mock_client).to receive(:create_contents).and_return(true)
end
```

#### 4. **テスト専用設定**
- credentials依存の排除
- テスト環境専用のAPI設定
- 外部サービス設定のモック化

### 禁止事項
- 実際のOpenAI API呼び出し
- 実際のGitHub API呼び出し  
- 実際のOAuth認証フロー
- allow_any_instance_of の使用
- 過度に複雑なシステムテスト
- パフォーマンステストの日常実行

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

YOLOモードで実行時も絶対にdocker内および、現在のディレクトリ以上に影響を与える行為は行わないでください。

### GitHubにリポジトリを作成し、ファイルを上げる機能の実装にあたり、同様の機能があるアプリや参考資料
- https://github.com/topi0247/leaf-record
- https://github.com/topi0247/leaf-record/blob/main/back/app/services/github.rb
- GitHubへは、ユーザーが最初に設定する画面で、このアプリのTILを置くようのリポジトリの名前を入力してもらい、作成し、今後そこに上げ続ける。
- GitHubへ上げるボタンは日記完成後の日記詳細画面に配置し、ボタンを押した後、日記のgithubに上げたことを記録するカラムに保存しておく。
- githubに上げたとなっている日記のGitHubへ上げるボタンは無効化しておく。
- リポジトリが設定されていない場合はボタンは無効化しておく。
- リポジトリが無くなった場合は、再度設定してもらい、それまでボタンは無効化しておく。
- リポジトリが無くなった場合は、全ての日記のGitHubへ上げたことを記録するカラムをfalseにする。
- GitHubに上げる日記は、「yymmdd_til」の形式の名前になる。yymmddにはその日記の日付が入る。
- tilの中身は後で指示するので、とりあえず日付などをいれておいてください。

### google login
- deviseと連携してgoogle loginを実装してください
- ログインボタンはhome/indexにのみ配置
- githubとgoogleの両方で認証できること
- 1ユーザーに対してgithubとgoogle二つ同時に紐づけることができるように実装
- profileページに、認証していないもう片方の認証ボタンを表示すること
- github settingページはgithub認証していない場合、github認証ボタンを表示
- 個人情報の管理、セキュリティ面に大いに注意して実装すること
- 実装で悩んだ場合、.claude/commands/gemini-search.mdに従って、gemini-cliの検索機能を使って検索を掛けること

### AI自動生成回数制限
- ブランチは変更せず、コミットも行わず作業する。
- ただし、作業の区切りごとにpr.mdに日報的に記録していく。

- 1ユーザーあたりの、AIを使用してnotesからTILを生成する回数に制限を設けます
- この上限のことを「種」と呼称する
- 種の数はdiary index/ new/ edit、profile詳細に表示
- 種のアイコンは\app\assets\imagesを使用
- 種を消費してTILを生成する
- リミット回数を管理するカラムを追加
- 🌱のマークのボタンを押すことで、使用可能回数+1
- X共有ボタンを押すことで+1
- 上限は5で、5を越えない。
- 種を消費することで
- 🌱のマークボタンで使用回数が+1されるのは、一日一回まで
- X共有ボタンで使用回数が+1されるのは一日一回まで
- 日本時間0時に、一日一回の制限は解除
- 🌱のボタンはdiary indexのヘッダー中央に配置
- 🌱のボタンを押すと、水色のエフェクトが弾けて、+1されたことがフラッシュで通知される。
- 種の無い状態で生成しようとすると、種が不足していることと、🌱のボタンとX共有で増加する旨を伝えるモーダルを表示(本日の増加上限を0/1や1/1のように添えておく)
- 増加上限はprofile 詳細画面に記載
- diary新規作成時の種不足時は、モーダルにAI生成無しで続けるボタンを配置
- diary編集時は、AI生成を仕様するかどうか確認するチェックボックスを設け、チェックがついている&notesがある場合のみAI生成を行い、その際種が無ければ、新規作成時同様、モーダルを表示し、AI生成無しで続けるボタン
