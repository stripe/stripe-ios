//
//  LinkInlineSignupView-CheckboxElement.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension LinkInlineSignupView {

    final class CheckboxElement: Element {
        let collectsUserInput: Bool = true

        weak var delegate: ElementDelegate?

        private let mode: LinkInlineSignupViewModel.Mode
        private let merchantName: String
        private let appearance: PaymentSheet.Appearance
        /// Controls the stroke color of the checkbox
        private let borderColor: UIColor

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
            // Force the border to match the passed in borderColor
            appearanceCopy.colors.componentBorder = borderColor

            let text = {
                switch mode {
                case .checkboxWithDefaultOptIn:
                    return STPLocalizedString(
                        "Save my info for faster checkout with Link",
                        """
                        Label for a checkbox that when checked allows the payment information
                        to be saved and used in future checkout sessions.
                        """
                    )
                case .checkbox, .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst:
                    return STPLocalizedString(
                        "Save your info for secure 1-click checkout with Link",
                        """
                        Label for a checkbox that when checked allows the payment information
                        to be saved and used in future checkout sessions.
                        """
                    )
                }
            }()

            let description: String? = {
                switch mode {
                case .checkbox, .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst:
                    return String.Localized.pay_faster_at_$merchant_and_thousands_of_merchants(
                        merchantDisplayName: merchantName
                    )
                case .checkboxWithDefaultOptIn:
                    return nil
                }
            }()

            let checkbox = CheckboxButton(
                text: text,
                description: description,
                theme: appearanceCopy.asElementsTheme,
                alwaysEmphasizeText: true
            )
            checkbox.addTarget(self, action: #selector(didToggleCheckbox), for: .touchUpInside)
            checkbox.isSelected = false

            return checkbox
        }()

        init(
            mode: LinkInlineSignupViewModel.Mode,
            merchantName: String,
            appearance: PaymentSheet.Appearance,
            borderColor: UIColor
        ) {
            self.mode = mode
            self.merchantName = merchantName
            self.appearance = appearance
            self.borderColor = borderColor
        }

        func setUserInteraction(isUserInteractionEnabled: Bool) {
            self.checkboxButton.isEnabled = isUserInteractionEnabled
            if isUserInteractionEnabled {
                self.checkboxButton.alpha = 1.0
            } else {
                self.checkboxButton.alpha = 0.6
            }

        }

        @objc func didToggleCheckbox() {
            delegate?.didUpdate(element: self)
        }
    }

}
