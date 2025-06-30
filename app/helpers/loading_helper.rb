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
    # onsubmitでグローバル関数を呼び出す
    options[:onsubmit] = "if(window.loadingController) window.loadingController.showDelayed(); #{options[:onsubmit]}".strip
    
    form_with(**options, &block)
  end
end