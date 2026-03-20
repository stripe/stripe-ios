//
//  PillSelectorElement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/20/26.

@_spi(STP) import StripeUICore
import UIKit

/// An `Element` wrapper around `PillSelectorView`.
final class PillSelectorElement: Element {
    weak var delegate: ElementDelegate?

    let collectsUserInput: Bool = true

    var view: UIView { selectorView }

    private let selectorView: PillSelectorView

    var selectedItemId: String { selectorView.selectedItemId }

    init(
        leftItem: PillSelectorItem,
        rightItem: PillSelectorItem,
        selectedItemId: String,
        caption: String? = nil,
        appearance: PaymentSheet.Appearance
    ) {
        selectorView = PillSelectorView(
            leftItem: leftItem,
            rightItem: rightItem,
            selectedItemId: selectedItemId,
            caption: caption,
            appearance: appearance
        )
        selectorView.delegate = self
    }

    func select(_ itemId: String) {
        selectorView.select(itemId, notifyDelegate: true)
    }

    func updateCaption(_ caption: String?) {
        selectorView.updateCaption(caption)
    }

    func setEnabled(_ enabled: Bool) {
        selectorView.setEnabled(enabled)
    }
}

// MARK: - PillSelectorViewDelegate

extension PillSelectorElement: PillSelectorViewDelegate {
    func pillSelectorView(_ view: PillSelectorView, didSelectItemWithId id: String) {
        delegate?.didUpdate(element: self)
    }
}
