//
//  BNPLFormHeaderView.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class BNPLFormHeaderView: UIView {
    private let appearance: PaymentSheet.Appearance
    private let paymentMethod: PaymentSheet.PaymentMethodType
    private let promotionsHelper: PaymentMethodMessagingPromotionsHelper
    private let fallbackView: UIView

    private var view: UIView

    private var theme: ElementsAppearance {
        appearance.asElementsTheme
    }

    /// Creates a BNPL header that can show payment method messaging promotion content when available.
    ///
    /// The view starts by displaying `fallback` so the form always has header content. When the view
    /// moves on screen, it asks `promotionsHelper` for promotion content for `paymentMethod`. If content
    /// is available, the fallback is replaced with the promotion text and the successful display is
    /// logged. If content is unavailable, the fallback remains visible and the unsuccessful display is
    /// logged.
    init(
        appearance: PaymentSheet.Appearance,
        paymentMethod: PaymentSheet.PaymentMethodType,
        promotionsHelper: PaymentMethodMessagingPromotionsHelper,
        fallback: SubtitleElement
    ) {
        self.appearance = appearance
        self.paymentMethod = paymentMethod
        self.promotionsHelper = promotionsHelper
        self.fallbackView = fallback.view
        self.view = fallbackView
        super.init(frame: .zero)

        // We initially set the view to the fallback, but we will update it to the promotion view if possible when we display
        addAndPinSubview(fallbackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        // If we are moved on screen we try to get the promotion content, display it, and log the attempt.
        // We check if promotion content is nil to know if we were successfully able to display it or not.
        // When the form is moved off screen didMoveToWindow() will be called with window == nil and we do nothing in this case.
        guard newWindow != nil else { return }

        view.removeFromSuperview()
        if let promotionContent = promotionsHelper.promotion(for: paymentMethod) {
            let textView = PMMEPromotionTextView(foregroundColor: theme.colors.primary)
            textView.delegate = self
            textView.linkTextAttributes = [
                .foregroundColor: theme.colors.primary,
                .underlineStyle: 0,
            ]
            textView.attributedText = NSMutableAttributedString.pmmePromoString(
                font: theme.fonts.subheadline,
                textColor: theme.colors.bodyText,
                template: promotionContent.promotion,
                substitution: nil,
                learnMoreText: promotionContent.learnMoreText,
                learnMoreUrl: promotionContent.infoUrl
            )
            addAndPinSubview(textView)
            isAccessibilityElement = false
            accessibilityElements = [textView]

            promotionsHelper.logDisplayedAnalytic(displayedSuccessfully: true)
        } else {
            addAndPinSubview(fallbackView)

            promotionsHelper.logDisplayedAnalytic(displayedSuccessfully: false)
        }
    }
}

extension BNPLFormHeaderView: UITextViewDelegate {
#if !os(visionOS)
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        // Only handle a direct tap on the link text.
        // Returning false for other interaction types suppresses previews, edit actions, and other system link affordances.
        guard interaction == .invokeDefaultAction else {
            return false
        }

        guard let infoUrl = promotionsHelper.promotion(for: paymentMethod)?.infoUrl else {
            stpAssertionFailure("Missing promotion content. This text view should never be shown while the promotion is not present.")
            return false
        }

        UIApplication.shared.open(infoUrl)
        return false
    }
#endif
}
