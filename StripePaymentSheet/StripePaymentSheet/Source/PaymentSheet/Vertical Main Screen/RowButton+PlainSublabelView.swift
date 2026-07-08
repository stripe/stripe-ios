//
//  RowButton+PlainSublabelView.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeUICore
#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

// MARK: - PlainSublabelView

extension RowButton {

    /// A single-line text sublabel used for static descriptive text beneath a payment method name.
    final class PlainSublabelView: UIView, SublabelView {

        var needsUnlimitedHeight: Bool { false }

        var hasText: Bool {
            guard let text = textLabel.text else {
                return false
            }
            return !text.isEmpty
        }

        let textLabel: UILabel

        init(
            text: String?,
            appearance: PaymentSheet.Appearance,
            isEmbedded: Bool
        ) {
            self.textLabel = UILabel()

            super.init(frame: .zero)

            if isEmbedded, let customFont = appearance.embeddedPaymentElement.row.subtitleFont {
                textLabel.font = customFont
            } else {
                textLabel.font = appearance.scaledFont(
                    for: appearance.font.base.regular,
                    style: .caption1,
                    maximumPointSize: 20
                )
            }
            textLabel.numberOfLines = 1
            textLabel.adjustsFontSizeToFitWidth = true
            textLabel.adjustsFontForContentSizeCategory = true
            textLabel.text = text

            let textColor: UIColor = {
                guard isEmbedded else {
                    return appearance.colors.componentPlaceholderText
                }
                switch appearance.embeddedPaymentElement.row.style {
                case .flatWithRadio, .flatWithCheckmark, .flatWithDisclosure:
                    return appearance.colors.textSecondary
                case .floatingButton:
                    return appearance.colors.componentPlaceholderText
                }
            }()

            textLabel.textColor = textColor
            addAndPinSubview(textLabel)
            self.isHidden = text?.isEmpty ?? true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setSublabel(text: String?, animated: Bool) {
            guard text != textLabel.text else { return }

            let showDuration = animated ? sublabelIsHiddenAnimationDuration : 0
            let fadeDuration = animated ? sublabelAlphaAnimationDuration : 0

            if let text {
                textLabel.text = text
                alpha = 0
                UIView.animate(withDuration: showDuration) {
                    self.isHidden = text.isEmpty
                }
                UIView.animate(
                    withDuration: fadeDuration,
                    delay: max(0, showDuration - fadeDuration)
                ) {
                    self.alpha = 1
                }
            } else {
                UIView.animate(withDuration: showDuration) {
                    self.textLabel.text = nil
                    self.isHidden = true
                    (self.superview as? UIView)?.setNeedsLayout()
                    (self.superview as? UIView)?.layoutIfNeeded()
                }
            }
        }

        func updateSelectedState(_ isRowSelected: Bool, willDisplayForm: Bool) {
            // Plain sublabel has no selection-dependent behavior
        }

    }
}
