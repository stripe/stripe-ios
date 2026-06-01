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
        style: PaymentSheet.UserInterfaceStyle,
        paymentMethod: PaymentSheet.PaymentMethodType,
        promotionsHelper: PaymentMethodMessagingPromotionsHelper
    ) {
        self.appearance = appearance
        self.style = style
        self.promotionsHelper = promotionsHelper
        guard let promotionContent = promotionsHelper.promotion(for: paymentMethod) else { return nil }
        self.promotion = promotionContent.promotion
        self.learnMoreText = promotionContent.learnMoreText
        self.infoUrl = promotionContent.infoUrl
        super.init(frame: .zero)

        switch style {
        case .automatic:
            break
        case .alwaysLight:
            overrideUserInterfaceStyle = .light
        case .alwaysDark:
            overrideUserInterfaceStyle = .dark
        }

        addAndPinSubview(textView)
        isAccessibilityElement = false
        accessibilityElements = [textView]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        promotionsHelper.logDisplayedAnalytic(displayedSuccessfully: true)
        super.didMoveToWindow()
    }

    private func openInfoModal() {
        PMMEInfoModal.present(infoUrl: infoUrl, style: pmmeStyle, from: self)
    }

    private var pmmeStyle: PaymentMethodMessagingElement.Appearance.UserInterfaceStyle {
        switch style {
        case .automatic:
            return .automatic
        case .alwaysLight:
            return .alwaysLight
        case .alwaysDark:
            return .alwaysDark
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

        openInfoModal()
        return false
    }
#endif
}
