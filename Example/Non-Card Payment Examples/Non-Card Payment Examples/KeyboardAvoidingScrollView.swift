//
//  KeyboardAvoidingScrollView.swift
//  Non-Card Payment Examples
//
//  Created by Ramon Torres on 9/13/21.
//  Copyright © 2021 Stripe. All rights reserved.
//

import UIKit

/// A UIScrollView subclass that actively prevents its content from being covered by the software keyboard.
final class KeyboardAvoidingScrollView: UIScrollView {

    /// Single source of truth for the additional bottom inset needed to avoid the keyboard.
    private var additionalBottomInset: CGFloat = 0 {
        didSet {
            adjustedContentInsetDidChange()
        }
    }

    override var adjustedContentInset: UIEdgeInsets {
        let inset = super.adjustedContentInset

        return UIEdgeInsets(
            top: inset.top,
            left: inset.left,
            bottom: inset.bottom + additionalBottomInset,
            right: inset.right)
    }

    override var scrollIndicatorInsets: UIEdgeInsets {
        get {
            let insets = super.scrollIndicatorInsets

            return UIEdgeInsets(
                top: insets.top,
                left: insets.left,
                bottom: insets.bottom + additionalBottomInset,
                right: insets.right)
        }
        set {
            super.scrollIndicatorInsets = newValue
        }
    }

    override var verticalScrollIndicatorInsets: UIEdgeInsets {
        get {
            let insets = super.verticalScrollIndicatorInsets

            return UIEdgeInsets(
                top: insets.top,
                left: insets.left,
                bottom: insets.bottom + additionalBottomInset,
                right: insets.right)
        }
        set {
            super.verticalScrollIndicatorInsets = newValue
        }
    }

    init() {
        super.init(frame: .zero)

        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardFrameChanged(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)

        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardFrameChanged(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)

        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Event Handling

private extension KeyboardAvoidingScrollView {

    @objc func keyboardFrameChanged(_ notification: Notification) {
        let userInfo = notification.userInfo

        guard let keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let absoluteFrame = convert(bounds, to: window)
        let intersection = absoluteFrame.intersection(keyboardFrame)

        animateAlongsideKeyboard(notification) {
            self.additionalBottomInset = intersection.height
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        animateAlongsideKeyboard(notification) {
            self.additionalBottomInset = 0.0

            if self.contentSize.height < self.bounds.height {
                self.contentOffset = .zero
            }
        }
    }
}

// MARK: - Animation

private extension KeyboardAvoidingScrollView {

    /// Animates changes to one or more views alongside the keyboard.
    /// - Parameters:
    ///   - notification: Keyboard change notification.
    ///   - animations: A block containing the changes to commit to the views.
    func animateAlongsideKeyboard(
        _ notification: Notification,
        animations: @escaping () -> Void
    ) {
        let userInfo = notification.userInfo

        guard
            let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber
        else {
            animations()
            return
        }

        // TODO: extract animation curve from `keyboardAnimationCurveUserInfoKey`
        // (see: http://www.openradar.me/42609976)

        UIView.animate(
            withDuration: duration.doubleValue,
            delay: 0,
            options: [.curveEaseOut],
            animations: animations
        )
    }
}
