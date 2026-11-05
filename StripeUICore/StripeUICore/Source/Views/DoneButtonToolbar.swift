//
//  DoneButtonToolbar.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 10/11/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(InternalOnlyAPI) public protocol DoneButtonToolbarDelegate: AnyObject {
    func didTapDone(_ toolbar: DoneButtonToolbar)
    func didTapCancel(_ toolbar: DoneButtonToolbar)
}

@_spi(InternalOnlyAPI) public extension DoneButtonToolbarDelegate {
    func didTapCancel(_ toolbar: DoneButtonToolbar) {
        // no-op, cancel button is hidden by default
    }
}

/// For internal SDK use only
@objc(STP_Internal_DoneButtonToolbar)
@_spi(InternalOnlyAPI) public final class DoneButtonToolbar: UIToolbar {

    public weak var doneButtonToolbarDelegate: DoneButtonToolbarDelegate?

    private var doneButton: UIBarButtonItem?
    private var doneButtonTintColor: UIColor = .systemBlue

    // MARK: - Initializers

    public init(delegate: DoneButtonToolbarDelegate?, showCancelButton: Bool = false, theme: ElementsAppearance = .default) {

        let needsAdditionalHeightBetweenKeyboard = LiquidGlassDetector.isEnabledInMerchantApp
        let height = needsAdditionalHeightBetweenKeyboard ? 52 : 44

        // Initializing w/ a frame stops autolayout from complaining on the first layout pass. On iOS 26, we set the height in order to give some space between the keyboard and the toolbar buttons.
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: height))
        self.doneButtonToolbarDelegate = delegate

        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(didTapDone)
        )
        self.doneButton = doneButton
        self.doneButtonTintColor = theme.colors.primary
        updateDoneButtonTintColor()
        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didTapCancel)
        )
        cancelButton.tintColor = theme.colors.secondaryText

        var items = [.flexibleSpace(), doneButton]
        if showCancelButton {
            items = [cancelButton] + items
        }

        setItems(items, animated: false)
        if !needsAdditionalHeightBetweenKeyboard {
            sizeToFit()
        }
        setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

#if !os(visionOS)
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateDoneButtonTintColor()
        }
    }
#endif

    // MARK: Internal Methods

    /// Applies the tint resolved for the current traits. On iOS 26, the system picks the done button's
    /// foreground (checkmark) color based on its tint, but doesn't re-evaluate it when a dynamic tint
    /// changes with the theme, so we re-assign a resolved color whenever the appearance changes.
    private func updateDoneButtonTintColor() {
        doneButton?.tintColor = doneButtonTintColor.resolvedColor(with: traitCollection)
    }

    @objc
    private func didTapDone() {
        doneButtonToolbarDelegate?.didTapDone(self)
    }

    @objc
    private func didTapCancel() {
        doneButtonToolbarDelegate?.didTapCancel(self)
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        guard LiquidGlassDetector.isEnabledInMerchantApp else {
            return hitView
        }

        // On iOS 26+, the toolbar eats all taps, even when you tap the empty space outside of the toolbar buttons, preventing you from dismissing the keyboard.
        // Hack: To tell if the touch is inside a button vs. the background, look at the touched view's width. The button is observed to be 38 points wide.
        let buttonWidthGuess = 50.0
        if hitView?.frame.size.width ?? 0 > buttonWidthGuess {
            // Don't return the background view or any other non-button view
            return nil
        }
        return hitView
    }
}
