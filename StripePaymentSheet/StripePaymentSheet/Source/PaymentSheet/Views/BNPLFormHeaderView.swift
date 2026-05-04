//
//  BNPLFormHeaderView.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeUICore
import UIKit

final class BNPLFormHeaderView: UIView {
    struct Configuration {
        let appearance: PaymentSheet.Appearance
        let promotion: String
        let learnMoreText: String
        let infoUrl: URL
    }

    let configuration: Configuration

    private var theme: ElementsAppearance {
        configuration.appearance.asElementsTheme
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
            template: configuration.promotion,
            substitution: nil,
            learnMoreText: configuration.learnMoreText,
            learnMoreUrl: configuration.infoUrl
        )
        return textView
    }()

    init(configuration: Configuration) {
        self.configuration = configuration
        super.init(frame: .zero)

        addAndPinSubview(textView)
        isAccessibilityElement = false
        accessibilityElements = [textView]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func openInfoModal() {
        let infoController = PMMEInfoModal(infoUrl: configuration.infoUrl, style: .alwaysDark)
        infoController.modalPresentationStyle = .formSheet
        window?.findTopMostPresentedViewController()?.present(infoController, animated: true)
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
