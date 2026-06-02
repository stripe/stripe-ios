//
//  BNPLFormHeaderView.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeUICore
import UIKit

final class BNPLFormHeaderView: UIView {
    private let appearance: PaymentSheet.Appearance
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

    init(
        appearance: PaymentSheet.Appearance,
        promotion: String,
        learnMoreText: String,
        infoUrl: URL
    ) {
        self.appearance = appearance
        self.promotion = promotion
        self.learnMoreText = learnMoreText
        self.infoUrl = infoUrl
        super.init(frame: .zero)

        addAndPinSubview(textView)
        isAccessibilityElement = false
        accessibilityElements = [textView]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
