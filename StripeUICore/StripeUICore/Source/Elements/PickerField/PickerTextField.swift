//
//  PickerTextField.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

// MARK: - PickerTextField

/**
 A subclass of `UITextField` that disables manual text entry.
 
 For internal SDK use only
 */
@objc(STP_Internal_PickerTextField)
class PickerTextField: UITextField {

    // MARK: Overrides

    override func caretRect(for position: UITextPosition) -> CGRect {
        // Disallow selection
        return .zero
    }

    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        // Disallow selection
        return []
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // Disallow context menu items
        false
    }

    // TODO(gbirch) temporarily removed to fix an Xcode 26 beta 5 bug that causes the availability check to not work and the code to crash on iOS <17
//    override func buildMenu(with builder: any UIMenuBuilder) {
        // autoFill bypasses the canPerformAction check, so we have to directly remove it from the UIMenuBuilder
        // enumerating every possible menu to remove them would be too tedious and require too much updating with newer iOS versions, so the others are left to the canPerformAction check
//        if #available(iOS 17.0, *) {
//            builder.remove(menu: .autoFill)
//        }
//    }
}
