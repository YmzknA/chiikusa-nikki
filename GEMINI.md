あなたはプロのプログラマーです。
以下の仕様書を読んでアプリを作成します。
作成に当たって、今回作業するのはdocker内でのみ行います。
docker内であれば、さまざまは操作を許可します。
gemなども適宜インストールして使用してください。
適宜ブランチを切ってコミットを行ってください。

# 🧑‍💻 日記アプリ 仕様書（プログラミング学習初級者向け）

## 1. アプリ概要
タイトルは仮です。「programing diary」

このアプリは、プログラミング学習を始めたばかりのユーザー向けに、毎日の学習記録を簡単に残せるように設計されています。記録は5段階評価と箇条書き形式の入力で構成され、AIがTIL（Today I Learned）形式の文章を生成してくれます。記録は公開・非公開を選べ、日記完成時のX（旧Twitter）への投稿誘導やGitHubにも連携可能です。

世界観としては、気軽に日記をつけてもらえる優しいイメージです。
キャラクターは雑草の見た目で、日記を付けるたびに雑草に水がかかり喜びます。
プログラミング要素はデザインの表に出さなくてもいいです。

---

## 2. 対象ユーザー

* プログラミング学習を始めたばかりの人
* 毎日の進捗を記録して振り返りたい人
* 成長をSNSやGitHubでシェアしたい人

---

## 3. 使用技術スタック

| 項目      | 技術                                    |
| ------- | ------------------------------------- |
| バックエンド  | Ruby on Rails 7                       |
| フロントエンド | Hotwire（Turbo/Stimulus）+ Tailwind CSS |
| データベース  | PostgreSQL                            |
| グラフ表示   | Chart.js（Stimulus経由で動的表示）             |
| 天気API   | OpenWeatherMap API または 気象庁API         |
| AI生成    | OpenAI API（GPT-4 nano）               |
| 認証      | GitHubログイン（OAuth）                     |
| 外部連携    | X（旧Twitter）投稿 / GitHub Push           |

---

## 4. 主な機能一覧

### 4.1 GitHubログイン

* GitHub連携でのみログイン可能（メール・パスワードは不要）
* OAuthを用いてユーザー情報とアクセストークンを取得

### 4.2 日記記録（1日1回）

#### 選択式（5段階評価）

* 今日の気分（😞〜😄）
* 学習のモチベーション（🧊〜🔥）
* 学習の進捗（✖️〜✅）

#### 箇条書き入力（自由記述）

* 例：

  * GitHubでforkを学んだ
  * Turbo Streamsを試した

#### AIによるTIL生成

* 箇条書き入力をもとに、TIL形式の文章を3案自動生成
* ユーザーは好きな1つを選んで日記を完成させる
* 箇条書き入力が無かった場合は、文章は無しで完成させる

#### 公開設定

* 日記は日毎に「公開」「非公開」から選択可

#### 外部連携

* 公開されたTILは、X（旧Twitter）に投稿（オプション）
* 完成画面に「GitHubにPush」ボタンあり（250626_til.mdなどに記録）

#### 日記を付けた日に雑草が生える機能
* githubの草機能と同じようなもの
* 配置される雑草はその日の気分で顔が変ります

### 4.3 統計・グラフ

* 直近30日間の記録をグラフで表示：

* 気分・モチベーション・進捗（棒グラフ or 円グラフ）

---

## 5. モデル構成(予定。適宜変更可能。その際は書き換えてください。)

```
User
  has_many :diaries
  belongs_to :location
  - github_id:string
  - username:string
  - access_token:string
  - location_id:bigint

Diary
  belongs_to :user
  belongs_to :daily_weather, optional: true
  has_many :diary_answers
  has_many :til_candidates
  - date:date
  - notes:text
  - til_text:text
  - selected_til_index:integer
  - is_public:boolean

Question
  has_many :answers
  - identifier:string  # mood, motivation, etc.
  - label:string
  - icon:string

Answer
  belongs_to :question
  - level:integer
  - label:string
  - emoji:string

DiaryAnswer
  belongs_to :diary
  belongs_to :question
  belongs_to :answer

TilCandidate
  belongs_to :diary
  - content:text
  - index:integer
```

---

## 6. API連携仕様

### OpenAI API（AI生成）

* 箇条書き入力に対するTIL候補を3つ生成

### GitHub連携

* アクセストークンによりTILをGitHubに追記（Markdown）

### X（旧Twitter）投稿

* OAuth経由で投稿（例：「#TodayILearned」など）

---

## 8. ページ構成（ルーティング案）

| URL                     | 内容                |
| ----------------------- | ----------------- |
| `/`                     | トップページ（概要・ログイン誘導） |
| `/auth/github/callback` | GitHubログイン処理      |
| `/diaries/new`          | 今日の記録入力フォーム       |
| `/diaries`              | 過去の記録一覧           |
| `/stats`                | グラフ・統計ページ         |
| `/profile`              | ユーザー設定    |

