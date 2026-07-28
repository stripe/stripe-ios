//
//  CurrencySelectorElement+TwoOptionSelectorViewAppearance.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/14/26.
//

import UIKit

extension CurrencySelectorElement.Appearance: TwoOptionSelectorViewAppearance {
    var trackBackground: UIColor { background }
    var pillBackground: UIColor { selectedBackground }
    var selectedTextColor: UIColor { selectedText }
    var unselectedTextColor: UIColor { text }
    var borderColor: UIColor { border }
    var captionColor: UIColor { textSecondary }
}
