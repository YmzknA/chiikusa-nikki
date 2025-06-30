module LoadingHelper
  def loading_link_to(name = nil, options = nil, html_options = nil, &block)
    if block_given?
      html_options = options || {}
      options = name
      name = capture(&block)
    else
      html_options ||= {}
    end
    
    # onclickでグローバル関数を呼び出す
    html_options[:onclick] = "if(window.loadingController) window.loadingController.showDelayed(); #{html_options[:onclick]}".strip
    
    link_to(name, options, html_options)
  end
  
  def loading_button_to(name = nil, options = nil, html_options = nil, &block)
    if block_given?
      html_options = options || {}
      options = name
      name = capture(&block)
    else
      html_options ||= {}
    end
    
    # onclickでグローバル関数を呼び出す
    html_options[:onclick] = "if(window.loadingController) window.loadingController.showDelayed(); #{html_options[:onclick]}".strip
    
    button_to(name, options, html_options)
  end
  
  def loading_form_with(**options, &block)
    # デバッグログ追加
    Rails.logger.debug "🔧 loading_form_with called with options: #{options.inspect}"
    
    # onsubmitでグローバル関数を呼び出す（onsubmitが実行されない問題を回避するため、より確実な方法を使用）
    original_onsubmit = options[:onsubmit]
    options[:onsubmit] = "console.log('📝 Form onsubmit triggered'); setTimeout(function() { if(window.loadingController) { console.log('✅ loadingController found, calling showDelayed'); window.loadingController.showDelayed(); } else { console.log('❌ loadingController not found'); } }, 10); #{original_onsubmit}".strip
    
    Rails.logger.debug "🔧 Final onsubmit: #{options[:onsubmit]}"
    
    form_with(**options, &block)
  end
end