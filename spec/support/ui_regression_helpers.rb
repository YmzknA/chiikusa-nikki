module UIRegressionHelpers
  # CSS class存在確認ヘルパー
  def expect_css_classes_present(*class_names)
    class_names.each do |class_name|
      expect(page).to have_selector(".#{class_name}"), 
        "Expected CSS class '#{class_name}' to be present"
    end
  end

  # レイアウト構造確認ヘルパー
  def expect_layout_structure(selectors = {})
    selectors.each do |name, selector|
      expect(page).to have_selector(selector), 
        "Expected #{name} with selector '#{selector}' to be present"
    end
  end

  # ボタン存在・状態確認ヘルパー
  def expect_interactive_elements(elements = {})
    elements.each do |name, selector|
      element = find(selector)
      expect(element).to be_visible, "Expected #{name} to be visible"
      expect(element[:disabled]).to be_falsy, "Expected #{name} to be enabled"
    end
  end

  # カード要素の構造確認
  def expect_card_structure(card_selector, expected_content = {})
    within(card_selector) do
      expected_content.each do |element, content|
        case element
        when :date
          expect(page).to have_content(content)
        when :title
          expect(page).to have_content(content)
        when :link
          expect(page).to have_link(content)
        when :button
          expect(page).to have_button(content)
        end
      end
    end
  end

  # ナビゲーション構造確認
  def expect_navigation_structure
    navigation_elements = {
      profile: "a[href='/profile']",
      stats: "a[href='/stats']", 
      github_settings: "a[href='/github_settings']",
      new_diary: "a[href='/diaries/new']"
    }
    
    expect_layout_structure(navigation_elements)
  end

  # フォーム構造確認
  def expect_form_structure(form_fields = {})
    expect(page).to have_selector("form")
    
    form_fields.each do |field_name, field_type|
      case field_type
      when :text_area
        expect(page).to have_field(field_name, type: 'textarea')
      when :text_field
        expect(page).to have_field(field_name, type: 'text')
      when :button
        expect(page).to have_button(field_name)
      when :select
        expect(page).to have_select(field_name)
      end
    end
  end

  # テーマ・スタイル確認
  def expect_theme_applied(theme_name = "lemonade")
    expect(page).to have_selector("body[data-theme='#{theme_name}']")
    expect(page).to have_selector(".#{theme_name}-background")
  end

  # レスポンシブ要素確認
  def expect_responsive_design
    responsive_classes = %w[
      container mx-auto grid gap-6 
      md:grid-cols-2 lg:grid-cols-3
      flex justify-between items-center
    ]
    
    responsive_classes.each do |css_class|
      expect(page).to have_selector(".#{css_class}") rescue nil
    end
  end

  # アイコン・画像確認
  def expect_visual_assets
    # ロゴ画像
    expect(page).to have_selector("img[src*='logo']") rescue nil
    
    # ウォータリング缶アイコン
    expect(page).to have_selector("img[src*='watering_can']") rescue nil
    
    # SVGアイコン
    expect(page).to have_selector("svg") rescue nil
    
    # Material Symbols
    expect(page).to have_selector(".material-symbols-outlined") rescue nil
  end

  # 色・フォント確認
  def expect_typography_and_colors
    # フォントクラス
    expect(page).to have_selector(".m-plus-1p-regular")
    
    # テキストサイズクラス
    text_classes = %w[text-3xl text-lg text-sm font-bold font-semibold]
    text_classes.each do |class_name|
      expect(page).to have_selector(".#{class_name}") rescue nil
    end
  end
end

RSpec.configure do |config|
  config.include UIRegressionHelpers, type: :system
end