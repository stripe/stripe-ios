//
//  STPInputTextFieldFormatter.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPInputTextFieldFormatter: NSObject {
    func isAllowedInput(_ input: String, to string: String, at range: NSRange) -> Bool {
        return true
    }

    func formattedText(
        from input: String,
        with defaultAttributes: [NSAttributedString.Key: Any]
    )
        -> NSAttributedString
    {
        return NSAttributedString(string: input, attributes: defaultAttributes)
    }
}

/// :nodoc:
extension STPInputTextFieldFormatter: UITextFieldDelegate {
    public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {

        let insertingIntoEmptyField =
            (textField.text?.count ?? 0) == 0 && range.location == 0 && range.length == 0
        let hasTextContentType = textField.textContentType != nil

        if hasTextContentType && insertingIntoEmptyField && string == " " {
            // Observed behavior w/ iOS 11.0 through 11.2.0 (latest checked):
            //
            // 1. UITextContentType suggestions are only available when textField is empty
            // 2. When user taps a QuickType suggestion for the `textContentType`, UIKit *first*
            // calls this method with `range:{0, 0} replacementString:@" "`
            // 3. If that succeeds (we return YES), this method is called again, this time with
            // the actual content to insert (and a space at the end)
            //
            // Therefore, always allow entry of a single space in order to support `textContentType`.
            return true
        }

        // string.isEmpty check always allows deletions
        return string.isEmpty || isAllowedInput(string, to: textField.text ?? "", at: range)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .done {
            _ = textField.resignFirstResponder()
            return false
        }
        return true
    }
}
