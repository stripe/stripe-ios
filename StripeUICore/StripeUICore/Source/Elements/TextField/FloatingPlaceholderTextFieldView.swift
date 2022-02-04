//
//  FloatingPlaceholderTextFieldView.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 7/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/**
 A helper view that contains a floating placeholder and a user-provided text field
 
 For internal SDK use only
 */
@objc(STP_Internal_FloatingPlaceholderTextFieldView)
class FloatingPlaceholderTextFieldView: FloatingPlaceholderView {
    
    // MARK: - Views
    
    let textField: UITextField
    
    // MARK: - Initializers
    
    init(textField: UITextField, image: UIImage? = nil) {
        self.textField = textField
        super.init(contentView: textField, image: image)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override var accessibilityValue: String? {
        set { assertionFailure() }
        get { return textField.text }
    }
}

/// :nodoc:
extension UITextField: FloatingPlaceholderContentView {
    var labelShouldFloat: Bool {
        return isEditing || !(text?.isEmpty ?? false)
    }
    
    var defaultResponder: UIView {
        return self
    }
}
