//
//  BNPLFormHeaderView.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeUICore
import UIKit

final class BNPLFormHeaderView: UIView {
    private let appearance: PaymentSheet.Appearance
    let style: PaymentSheet.UserInterfaceStyle
    let promotionsHelper: PaymentMethodMessagingPromotionsHelper
    let promotion: String
    let learnMoreText: String
    let infoUrl: URL

    private var theme: ElementsAppearance {
        appearance.asElementsTheme
    }

    private lazy var textView: PMMEPromotionTextView = {
        let textView = PMMEPromotionTextView(foregroundColor: theme.colors.primary)
        textView.delegate = self
        textView.linkTextAttributes = [
            .foregroundColor: theme.colors.primary,
            .underlineStyle: 0,
        ]
        textView.attributedText = NSMutableAttributedString.pmmePromoString(
            font: theme.fonts.subheadline,
            textColor: theme.colors.bodyText,
            template: promotion,
            substitution: nil,
            learnMoreText: learnMoreText,
            learnMoreUrl: infoUrl
        )
        return textView
    }()

    init?(
        appearance: PaymentSheet.Appearance,
        paymentMethod: PaymentSheet.PaymentMethodType,
        promotionsHelper: PaymentMethodMessagingPromotionsHelper
    ) {
        self.appearance = appearance
        self.promotionsHelper = promotionsHelper
        guard let promotionContent = promotionsHelper.promotion(for: paymentMethod) else { return nil }
        self.promotion = promotionContent.promotion
        self.learnMoreText = promotionContent.learnMoreText
        self.infoUrl = promotionContent.infoUrl
        super.init(frame: .zero)

        addAndPinSubview(textView)
        isAccessibilityElement = false
        accessibilityElements = [textView]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        // If we are moved on screen we log that the promotion was displayed successfully.
        // When the form is moved off screen didMoveToWindow() will be called with window == nil and we do nothing in this case.
        guard window != nil else { return }
        promotionsHelper.logDisplayedAnalytic(displayedSuccessfully: true)
    }

    private func openInfoModal() {
        PMMEInfoModal.present(infoUrl: infoUrl, style: traitCollection.isDarkMode ? .alwaysDark : .alwaysLight, from: self)
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

        openInfoModal()
        return false
    }
#endif
}
