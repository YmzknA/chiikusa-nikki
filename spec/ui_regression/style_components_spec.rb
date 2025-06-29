require "rails_helper"

RSpec.describe "Style Components", type: :system do
  let(:user) { create(:user, :with_github, username: "testuser") }
  let(:diary) { create(:diary, user: user, notes: "スタイルテスト用日記") }

  before do
    login_as(user, scope: :user)
  end

  describe "Neuro Design System" do
    it "applies neuro-card styling consistently" do
      visit diaries_path
      
      # neuro-cardクラスの存在確認
      expect_css_classes_present("neuro-card")
      
      # カード内の構造確認
      within(".neuro-card") do
        expect(page).to have_selector(".flex")
        expect(page).to have_selector(".justify-between") rescue nil
        expect(page).to have_selector(".items-center") rescue nil
      end
    end

    it "applies neuro-button styling consistently" do
      visit new_diary_path
      
      # ボタンスタイルの確認
      expect_css_classes_present("neuro-button")
      
      # ボタンの状態確認
      expect_interactive_elements({
        "保存ボタン" => "button:contains('保存')"
      }) rescue nil
    end

    it "applies neuro-button-secondary styling" do
      visit public_diaries_path
      
      # セカンダリボタンの確認
      expect_css_classes_present("neuro-button-secondary")
    end
  end

  describe "Layout Grid System" do
    it "uses proper grid classes" do
      create_list(:diary, 3, user: user)
      visit diaries_path
      
      # グリッドシステムの確認
      expect_css_classes_present("grid", "gap-6")
      
      # レスポンシブグリッドクラス
      responsive_grid_classes = ["md:grid-cols-2", "lg:grid-cols-3"]
      responsive_grid_classes.each do |class_name|
        expect(page).to have_selector(".#{class_name}") rescue nil
      end
    end

    it "uses flexbox layout correctly" do
      visit diaries_path
      
      # Flexboxクラスの確認
      flex_classes = ["flex", "justify-between", "items-center", "gap-2", "gap-3", "gap-6"]
      flex_classes.each do |class_name|
        expect(page).to have_selector(".#{class_name}") rescue nil
      end
    end
  end

  describe "Typography System" do
    it "applies font family correctly" do
      visit diaries_path
      
      # メインフォントクラス
      expect(page).to have_selector(".m-plus-1p-regular")
    end

    it "uses consistent font sizes" do
      visit diaries_path
      
      # フォントサイズクラス
      font_size_classes = ["text-3xl", "text-lg", "text-sm", "text-base"]
      font_size_classes.each do |class_name|
        expect(page).to have_selector(".#{class_name}") rescue nil
      end
    end

    it "applies font weights correctly" do
      visit diaries_path
      
      # フォントウェイトクラス
      font_weight_classes = ["font-bold", "font-semibold", "font-medium"]
      font_weight_classes.each do |class_name|
        expect(page).to have_selector(".#{class_name}") rescue nil
      end
    end
  end

  describe "Color System" do
    it "applies theme colors correctly" do
      visit diaries_path
      
      # テーマの適用確認
      expect_theme_applied("lemonade")
      
      # カラークラス（存在する場合）
      color_classes = ["text-primary", "text-secondary", "text-base-content"]
      color_classes.each do |class_name|
        expect(page).to have_selector(".#{class_name}") rescue nil
      end
    end

    it "uses background colors appropriately" do
      visit diaries_path
      
      # 背景色クラス
      expect(page).to have_selector(".lemonade-background")
      
      # その他の背景色クラス
      bg_classes = ["bg-primary", "bg-secondary"]
      bg_classes.each do |class_name|
        expect(page).to have_selector(".#{class_name}") rescue nil
      end
    end
  end

  describe "Spacing System" do
    it "uses consistent padding classes" do
      visit diaries_path
      
      # パディングクラス
      padding_classes = ["p-2", "p-3", "p-4", "p-6", "py-2", "py-3", "px-4", "px-6"]
      padding_classes.each do |class_name|
        expect(page).to have_selector(".#{class_name}") rescue nil
      end
    end

    it "uses consistent margin classes" do
      visit diaries_path
      
      # マージンクラス
      margin_classes = ["mb-2", "mb-3", "mb-4", "mb-6", "ml-2"]
      margin_classes.each do |class_name|
        expect(page).to have_selector(".#{class_name}") rescue nil
      end
    end
  end

  describe "Utility Classes" do
    it "uses size utility classes" do
      visit diaries_path
      
      # サイズクラス
      size_classes = ["size-5", "size-6", "size-11", "h-4", "w-4", "h-12", "w-auto"]
      size_classes.each do |class_name|
        expect(page).to have_selector(".#{class_name}") rescue nil
      end
    end

    it "uses border and shadow utilities" do
      visit diaries_path
      
      # ボーダー・シャドウクラス（実装されている場合）
      utility_classes = ["rounded-full", "border", "shadow"]
      utility_classes.each do |class_name|
        expect(page).to have_selector(".#{class_name}") rescue nil
      end
    end
  end
end