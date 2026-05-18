//
//  PMMERowSublabelView.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class PMMERowSublabelView: UIView {
    private static let visibilityAnimationDuration: TimeInterval = 0.2
    private static let fadeAnimationDuration: TimeInterval = 0.1

    private let appearance: PaymentSheet.Appearance
    private var content: RowButton.PaymentMethodMessagingContent?
    private var isRowSelected = false

    private(set) var isExpanded = false
    var hasContent: Bool {
        return content != nil
    }

    private(set) lazy var promotionTextView: PMMEPromotionTextView = {
        let textView = PMMEPromotionTextView(foregroundColor: appearance.colors.primary)
        textView.delegate = self
        textView.isHidden = true
        textView.alpha = 0
        return textView
    }()

    var onLayoutNeedsUpdate: (() -> Void)?

    init(
        appearance: PaymentSheet.Appearance,
        content: RowButton.PaymentMethodMessagingContent?
    ) {
        self.appearance = appearance
        self.content = content
        super.init(frame: .zero)

        isHidden = true
        addAndPinSubview(promotionTextView)

        if let content {
            applyContent(content)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setRowSelected(_ isSelected: Bool) {
        isRowSelected = isSelected
        updateExpandedState()
    }

    func populateIfNeeded(_ content: RowButton.PaymentMethodMessagingContent) {
        guard self.content == nil else {
            return
        }

        self.content = content
        applyContent(content)
        updateExpandedState()
    }

    private func updateExpandedState() {
        setExpanded(isRowSelected && hasContent)
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

        UIView.animate(withDuration: Self.visibilityAnimationDuration) { [self] in
            self.isHidden = false
            promotionTextView.isHidden = false
            onLayoutNeedsUpdate?()
        }

        UIView.animate(
            withDuration: Self.fadeAnimationDuration,
            delay: Self.visibilityAnimationDuration - Self.fadeAnimationDuration
        ) { [self] in
            promotionTextView.alpha = 1
        }
    }

    private func collapse() {
        UIView.animate(withDuration: Self.visibilityAnimationDuration) { [self] in
            self.isHidden = true
            promotionTextView.isHidden = true
            onLayoutNeedsUpdate?()
        }

        UIView.animate(withDuration: Self.visibilityAnimationDuration) { [self] in
            promotionTextView.alpha = 0
        }
    }

    private func applyContent(_ content: RowButton.PaymentMethodMessagingContent) {
        promotionTextView.attributedText = NSMutableAttributedString.pmmePromoString(
            font: appearance.scaledFont(for: appearance.font.base.medium, style: .caption1, maximumPointSize: 20),
            textColor: appearance.colors.text,
            template: content.promotion,
            substitution: nil,
            learnMoreText: content.learnMoreText,
            learnMoreUrl: content.infoUrl
        )
    }

    private func openInfoModal() {
        guard let content else {
            stpAssertionFailure("PMME row sublabel tried to present the PMME info modal without content.")
            return
        }

        PMMEInfoModal.present(infoUrl: content.infoUrl, style: .automatic, from: self)
    }
}

extension PMMERowSublabelView: UITextViewDelegate {
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
