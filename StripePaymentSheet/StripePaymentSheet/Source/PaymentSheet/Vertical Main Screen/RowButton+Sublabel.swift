//
//  RowButtonSublabel.swift
//  StripePaymentSheet
//
//  Created by George Birch on 5/19/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension RowButton {
    
    fileprivate static let sublabelVisibilityAnimationDuration: TimeInterval = 0.2
    fileprivate static let sublabelFadeAnimationDuration: TimeInterval = 0.1
    
    // TODO: documentation
    protocol SublabelView: UIView {
        var needsUnlimitedHeight: Bool { get }
        var hasText: Bool { get }
        func setSublabel(text: String?, animated: Bool)
        func updateSelectedState(_ isRowSelected: Bool, willDisplayForm: Bool)
    }
}


// MARK: - Payment Method Messaging variant

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
        private var infoUrl: URL? = nil

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

        // TODO: clean up the logic here some
        // TODO: if we are already expanded and we are selected, should we try to avoid even doing the promotion check + log?
        func updateSelectedState(_ isRowSelected: Bool, willDisplayForm: Bool) {
            if isRowSelected && !willDisplayForm {
                // If selected, get PMME content (logging an exposure), and expand if content is available
                // PMM data is not always available on initial load/display of a RowButton, so we check for it right before attempting to dispaly
                if let promotionContent = promotionsHelper.promotion(for: paymentMethodType) {
                    applyContent(promotionContent)
                    setExpanded(true)
                }
            } else {
                setExpanded(false)
            }
        }

        // Track expansion state to avoid re-expanding or re-collapsing when already expanded/collapsed
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

// MARK: - plain variant

extension RowButton {
    
    class PlainSublabelView: UIView, SublabelView {
        
        // the normal sublabel should have it's height constrained by the row button
        var needsUnlimitedHeight: Bool { false }
        var hasText: Bool {
            guard let text = self.textLabel.text else {
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
            let sublabel = UILabel()
            if isEmbedded, let customFont = appearance.embeddedPaymentElement.row.subtitleFont {
                sublabel.font = customFont
            } else {
                sublabel.font = appearance.scaledFont(for: appearance.font.base.regular, style: .caption1, maximumPointSize: 20)
            }
            sublabel.numberOfLines = 1
            sublabel.adjustsFontSizeToFitWidth = true
            sublabel.adjustsFontForContentSizeCategory = true
            sublabel.text = text

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

            sublabel.textColor = textColor
            self.textLabel = sublabel
            super.init(frame: .zero)

            addAndPinSubview(sublabel)
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
            // no-op: plain sublabel variant doesn't do anything with selection state
        }
    }
}
