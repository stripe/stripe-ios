//
//  TwoOptionSelectorElement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/20/26.

@_spi(STP) import StripeUICore
import UIKit

/// An `Element` wrapper around `TwoOptionSelectorView`.
final class TwoOptionSelectorElement: Element {
    weak var delegate: ElementDelegate?

    let collectsUserInput: Bool = true

    var view: UIView { selectorView }

    private let selectorView: TwoOptionSelectorView

    var selectedItemId: String { selectorView.selectedItemId }

    init(
        leftItem: TwoOptionSelectorItem,
        rightItem: TwoOptionSelectorItem,
        selectedItemId: String,
        caption: String? = nil,
        appearance: PaymentSheet.Appearance
    ) {
        selectorView = TwoOptionSelectorView(
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

// MARK: - TwoOptionSelectorViewDelegate

extension TwoOptionSelectorElement: TwoOptionSelectorViewDelegate {
    func twoOptionSelectorView(_ view: TwoOptionSelectorView, didSelectItemWithId id: String) {
        delegate?.didUpdate(element: self)
    }
}
