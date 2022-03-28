//
//  LinkInlineSignupView-CheckboxElement.swift
//  StripeiOS
//
//  Created by Ramon Torres on 1/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
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
            // TODO(ramont): Localize
            let checkbox = CheckboxButton(
                text: "Save my info for secure 1-click checkout",
                description: String(format: "Pay faster at %@ and thousands of merchants.", merchantName),
                appearance: appearance
            )

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
