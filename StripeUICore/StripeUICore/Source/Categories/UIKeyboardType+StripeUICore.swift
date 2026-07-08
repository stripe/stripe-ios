//
//  UIKeyboardType+StripeUICore.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 10/11/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension UIKeyboardType {
    /// Whether this keyboard has a return key
    var hasReturnKey: Bool {
        switch self {
        case .default,
             .asciiCapable,
             .numbersAndPunctuation,
             .URL,
             .namePhonePad,
             .emailAddress,
             .webSearch:
            return true
        case .numberPad,
             .phonePad,
             .decimalPad,
             .twitter,
             .asciiCapableNumberPad:
            return false
        @unknown default:
            return true
        }
    }
}
