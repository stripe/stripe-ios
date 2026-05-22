//
//  RowButton+Sublabel.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

// MARK: - SublabelView protocol

extension RowButton {

    /// Defines the interface for sublabel views displayed beneath the primary label in a `RowButton`.
    /// Conforming types manage their own visibility transitions and text state.
    protocol SublabelView: UIView {
        /// Whether this sublabel variant needs to expand beyond the standard row height.
        var needsUnlimitedHeight: Bool { get }
        /// Whether the sublabel currently contains displayable content.
        var hasText: Bool { get }
        /// The current plain-text representation of the sublabel, if any.
        var text: String? { get }
        /// Updates the displayed text, optionally animating the visibility transition.
        func setSublabel(newText: String?, animated: Bool)
        /// Notifies the sublabel that the parent row's selection state changed.
        func updateSelectedState(_ isRowSelected: Bool)
    }
}

// MARK: - PlainSublabelView

extension RowButton {

    /// A single-line text sublabel used for static descriptive text beneath a payment method name.
    final class PlainSublabelView: UIView, SublabelView {

        var needsUnlimitedHeight: Bool { false }

        var hasText: Bool {
            currentText?.isEmpty == false
        }

        var text: String? { currentText }

        private var currentText: String?
        private let textLabel: UILabel

        private static let visibilityAnimationDuration: TimeInterval = 0.2
        private static let fadeAnimationDuration: TimeInterval = 0.1

        init(
            text: String?,
            appearance: PaymentSheet.Appearance,
            isEmbedded: Bool
        ) {
            self.currentText = text
            self.textLabel = UILabel()

            super.init(frame: .zero)

            configureLabel(appearance: appearance, isEmbedded: isEmbedded)
            textLabel.text = text
            textLabel.isHidden = text?.isEmpty ?? true

            addAndPinSubview(textLabel)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setSublabel(newText: String?, animated: Bool) {
            guard newText != currentText else { return }

            let showDuration = animated ? Self.visibilityAnimationDuration : 0
            let fadeDuration = animated ? Self.fadeAnimationDuration : 0

            if let newText {
                currentText = newText
                textLabel.text = newText
                alpha = 0
                UIView.animate(withDuration: showDuration) {
                    self.isHidden = newText.isEmpty
                }
                UIView.animate(
                    withDuration: fadeDuration,
                    delay: max(0, showDuration - fadeDuration)
                ) {
                    self.alpha = 1
                }
            } else {
                UIView.animate(withDuration: showDuration) {
                    self.currentText = nil
                    self.isHidden = true
                    self.superview?.setNeedsLayout()
                    self.superview?.layoutIfNeeded()
                }
            }
        }

        func updateSelectedState(_ isRowSelected: Bool) {
            // Plain sublabel has no selection-dependent behavior
        }

        // MARK: - Private

        private func configureLabel(appearance: PaymentSheet.Appearance, isEmbedded: Bool) {
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
            textLabel.textColor = Self.resolveTextColor(appearance: appearance, isEmbedded: isEmbedded)
        }

        private static func resolveTextColor(
            appearance: PaymentSheet.Appearance,
            isEmbedded: Bool
        ) -> UIColor {
            guard isEmbedded else {
                return appearance.colors.componentPlaceholderText
            }
            switch appearance.embeddedPaymentElement.row.style {
            case .flatWithRadio, .flatWithCheckmark, .flatWithDisclosure:
                return appearance.colors.textSecondary
            case .floatingButton:
                return appearance.colors.componentPlaceholderText
            }
        }
    }
}
