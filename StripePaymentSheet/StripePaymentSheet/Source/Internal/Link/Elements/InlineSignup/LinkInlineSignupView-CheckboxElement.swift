//
//  LinkInlineSignupView-CheckboxElement.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
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
            var appearanceCopy = appearance
            if appearance.cornerRadius == nil && LiquidGlassDetector.isEnabledInMerchantApp {
                // Make the checkbox in Link use the same background color as its container, which is componentBackground
                appearanceCopy.colors.background = appearance.colors.componentBackground
            }
            // Force the border to match the passed in borderColor
            appearanceCopy.colors.componentBorder = borderColor

            let text = {
                switch mode {
                case .signupOptIn:
                    return STPLocalizedString(
                        "Create an account with Link for faster checkout across the web",
                        """
                        Label for a checkbox that when checked allows the payment information
                        to be saved and used in future checkout sessions.
                        """
                    )
                case .checkbox, .checkboxWithDefaultOptIn:
                    return STPLocalizedString(
                        "Save my info for faster checkout with Link",
                        """
                        Label for a checkbox that when checked allows the payment information
                        to be saved and used in future checkout sessions.
                        """
                    )
                case .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst:
                    return STPLocalizedString(
                        "Save your info for secure 1-click checkout with Link",
                        """
                        Label for a checkbox that when checked allows the payment information
                        to be saved and used in future checkout sessions.
                        """
                    )
                }
            }()

            let leadingIcon: NSTextAttachment? = {
                guard mode == .signupOptIn else {
                    return nil
                }
                return LinkUI.inlineLogo(
                    withScale: 1.3,
                    forFont: appearance.asElementsTheme.fonts.footnoteEmphasis
                )
            }()

            let result: NSAttributedString = {
                if let leadingIcon {
                    // Handle the case with a Link logo
                    let linkRange = (text as NSString).range(of: "Link")
                    if linkRange.location != NSNotFound {
                        let mutableResult = NSMutableAttributedString(string: text)

                        // Create the paragraph style
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.lineSpacing = LinkUI.lineSpacing(
                            fromRelativeHeight: 1.0,
                            textStyle: .caption
                        )

                        // Replace "Link" with the icon
                        let attachmentString = NSAttributedString(attachment: leadingIcon)
                        mutableResult.replaceCharacters(in: linkRange, with: NSAttributedString(attachment: leadingIcon))

                        mutableResult.addAttributes(
                            [.paragraphStyle: paragraphStyle],
                            range: NSRange(location: 0, length: mutableResult.length)
                        )

                        return mutableResult
                    }
                }

                // Default case: just use the formatted text without icon
                let formattedString = NSMutableAttributedString(string: text)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = LinkUI.lineSpacing(
                    fromRelativeHeight: 1.0,
                    textStyle: .caption
                )
                formattedString.addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: formattedString.length))

                return formattedString
            }()

            let description: String? = {
                switch mode {
                case .checkbox, .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst:
                    return String.Localized.pay_faster_at_$merchant_and_thousands_of_merchants(
                        merchantDisplayName: merchantName
                    )
                case .checkboxWithDefaultOptIn, .signupOptIn:
                    return nil
                }
            }()

            let checkbox = CheckboxButton(
                attributedText: result,
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
