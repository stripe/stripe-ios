//
//  RowButton+Sublabel.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

// MARK: - SublabelView protocol

extension RowButton {

    fileprivate static let sublabelVisibilityAnimationDuration: TimeInterval = 0.2
    fileprivate static let sublabelFadeAnimationDuration: TimeInterval = 0.1

    /// Defines the interface for sublabel views displayed beneath the primary label in a `RowButton`.
    /// Conforming types manage their own visibility transitions and text state.
    protocol SublabelView: UIView {
        /// Whether this sublabel variant needs to expand beyond the standard row height.
        var needsUnlimitedHeight: Bool { get }
        /// Whether the sublabel currently contains displayable content.
        var hasText: Bool { get }
        /// Updates the displayed text, optionally animating the visibility transition.
        func setSublabel(text: String?, animated: Bool)
        /// Notifies the sublabel that the parent row's selection state changed.
        func updateSelectedState(_ isRowSelected: Bool, willDisplayForm: Bool)
    }
}

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

            let showDuration = animated ? sublabelVisibilityAnimationDuration : 0
            let fadeDuration = animated ? sublabelFadeAnimationDuration : 0

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
                    self.superview?.setNeedsLayout()
                    self.superview?.layoutIfNeeded()
                }
            }
        }

        func updateSelectedState(_ isRowSelected: Bool, willDisplayForm: Bool) {
            // Plain sublabel has no selection-dependent behavior
        }

    }
}

// MARK: - PaymentMethodMessagingSublabelView

extension RowButton {

    final class PaymentMethodMessagingSublabelView: UIView, SublabelView {

        // Payment Method Messaging content can be larger than a normal sublabel
        var needsUnlimitedHeight: Bool { true }
        var hasText: Bool {
            guard let attributedText = promotionTextView.attributedText else {
                return false
            }
            return !attributedText.string.isEmpty
        }

        private let appearance: PaymentSheet.Appearance
        private let paymentMethodType: PaymentSheet.PaymentMethodType
        private let promotionsHelper: PaymentMethodMessagingPromotionsHelper

        private var isExpanded = false
        private var infoUrl: URL?

        private lazy var promotionTextView: PMMEPromotionTextView = {
            let textView = PMMEPromotionTextView(foregroundColor: appearance.colors.primary)
            textView.delegate = self
            textView.isHidden = true
            textView.alpha = 0
            return textView
        }()

        init(
            appearance: PaymentSheet.Appearance,
            paymentMethodType: PaymentSheet.PaymentMethodType,
            promotionsHelper: PaymentMethodMessagingPromotionsHelper
        ) {
            self.appearance = appearance
            self.paymentMethodType = paymentMethodType
            self.promotionsHelper = promotionsHelper
            super.init(frame: .zero)

            isHidden = true
            addAndPinSubview(promotionTextView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setSublabel(text: String?, animated: Bool) {
            // If there is no actual text then there is no issue
            guard let text, !text.isEmpty else {
                return
            }
            // Otherwise we have an issue since the PMM sublabel doesn't support this
            stpAssertionFailure("Setting sublabel not supported with payment method messaging sublabel. setSublabel() should only be called on the plain variant")
        }

        func updateSelectedState(_ isRowSelected: Bool, willDisplayForm: Bool) {
            if isRowSelected && !willDisplayForm {
                if let promotionContent = promotionsHelper.promotion(for: paymentMethodType) {
                    applyContent(promotionContent)
                    setExpanded(true)
                }
            } else {
                setExpanded(false)
            }
        }

        private func setExpanded(_ isExpanded: Bool) {
            guard self.isExpanded != isExpanded else {
                return
            }

            self.isExpanded = isExpanded

            if isExpanded {
                expand()
            } else {
                collapse()
            }
        }

        private func expand() {
            promotionTextView.alpha = 0

            UIView.animate(withDuration: sublabelVisibilityAnimationDuration) { [self] in
                self.isHidden = false
                promotionTextView.isHidden = false
            }

            UIView.animate(
                withDuration: sublabelFadeAnimationDuration,
                delay: sublabelVisibilityAnimationDuration - sublabelFadeAnimationDuration
            ) { [self] in
                promotionTextView.alpha = 1
            }
        }

        private func collapse() {
            UIView.animate(withDuration: sublabelVisibilityAnimationDuration) { [self] in
                self.isHidden = true
                promotionTextView.isHidden = true
            }

            UIView.animate(withDuration: sublabelVisibilityAnimationDuration) { [self] in
                promotionTextView.alpha = 0
            }
        }

        private func applyContent(_ content: PaymentMethodMessagingPromotionsHelper.PromotionContent) {
            promotionTextView.attributedText = NSMutableAttributedString.pmmePromoString(
                font: appearance.scaledFont(for: appearance.font.base.medium, style: .caption1, maximumPointSize: 20),
                textColor: appearance.colors.text,
                template: content.promotion,
                substitution: nil,
                learnMoreText: content.learnMoreText,
                learnMoreUrl: content.infoUrl
            )
            self.infoUrl = content.infoUrl
        }

        private func openInfoModal() {
            guard let infoUrl else {
                stpAssertionFailure("PMME row sublabel tried to present the PMME info modal without content.")
                return
            }

            PMMEInfoModal.present(infoUrl: infoUrl, style: .automatic, from: self)
        }
    }
}

extension RowButton.PaymentMethodMessagingSublabelView: UITextViewDelegate {
#if !os(visionOS)
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        guard interaction == .invokeDefaultAction else {
            return false
        }

        openInfoModal()
        return false
    }
#endif
}
