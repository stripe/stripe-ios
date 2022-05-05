//
//  LinkInlineSignupView-CheckboxElement.swift
//  StripeiOS
//
//  Created by Ramon Torres on 1/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension LinkInlineSignupView {

    final class CheckboxElement: Element {
        weak var delegate: ElementDelegate?

        private let merchantName: String
        private let appearance: PaymentSheet.Appearance

        var view: UIView {
            return checkboxButton
        }

        var isChecked: Bool {
            get {
                checkboxButton.isSelected
            }
            set {
                checkboxButton.isSelected = newValue
            }
        }

        private lazy var checkboxButton: CheckboxButton = {
            // Make the checkbox in Link use background color as it's background instead of componenetBackground
            var appearanceCopy = appearance
            appearanceCopy.colors.componentBackground = appearance.colors.background

            let text = STPLocalizedString(
                "Save my info for secure 1-click checkout",
                """
                Label for a checkbox that when checked allows the payment information
                to be saved and used in future checkout sessions.
                """
            )

            let description = String.Localized.pay_faster_at_$merchant_and_thousands_of_merchants(
                merchantDisplayName: merchantName
            )

            let checkbox = CheckboxButton(text: text, description: description, theme: appearanceCopy.asElementsTheme)
            checkbox.addTarget(self, action: #selector(didToggleCheckbox), for: .touchUpInside)
            checkbox.isSelected = false

            return checkbox
        }()

        init(merchantName: String, appearance: PaymentSheet.Appearance) {
            self.merchantName = merchantName
            self.appearance = appearance
        }

        @objc func didToggleCheckbox() {
            delegate?.didUpdate(element: self)
        }
    }

}
