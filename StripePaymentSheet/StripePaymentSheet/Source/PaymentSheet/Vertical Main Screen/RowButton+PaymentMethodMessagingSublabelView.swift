//
//  RowButton+PaymentMethodMessagingSublabelView.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

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
                // If selected, get PMME content, log an attempt to display, and expand if applicable
                // PMM data is not always available on initial load/display of a RowButton, so we check for it right before attempting to display
                let promotionContent = promotionsHelper.promotion(for: paymentMethodType)
                if let promotionContent {
                    // In this case we want until expand() to log the analytic so that we avoid repeat logging when the row is simply re-selected
                    applyContent(promotionContent)
                    setExpanded(true)
                } else {
                    promotionsHelper.logDisplayedAnalytic(displayedSuccessfully: false)
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
            // Log analytic
            promotionsHelper.logDisplayedAnalytic(displayedSuccessfully: true)

            promotionTextView.alpha = 0

            UIView.animate(withDuration: sublabelIsHiddenAnimationDuration) { [self] in
                self.isHidden = false
                promotionTextView.isHidden = false
            }

            UIView.animate(
                withDuration: sublabelAlphaAnimationDuration,
                delay: sublabelIsHiddenAnimationDuration - sublabelAlphaAnimationDuration
            ) { [self] in
                promotionTextView.alpha = 1
            }
        }

        private func collapse() {
            UIView.animate(withDuration: sublabelIsHiddenAnimationDuration) { [self] in
                self.isHidden = true
                promotionTextView.isHidden = true
            }

            UIView.animate(withDuration: sublabelIsHiddenAnimationDuration) { [self] in
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

        guard let infoUrl else {
            stpAssertionFailure("PMME row sublabel tried to open info link without content.")
            return false
        }

        UIApplication.shared.open(infoUrl)
        return false
    }
#endif
}
