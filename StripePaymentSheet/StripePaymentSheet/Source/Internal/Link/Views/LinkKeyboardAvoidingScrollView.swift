//
//  LinkKeyboardAvoidingScrollView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

/// A UIScrollView subclass that actively prevents its content from being covered by the software keyboard.
/// For internal SDK use only
@objc(STP_Internal_LinkKeyboardAvoidingScrollView)
final class LinkKeyboardAvoidingScrollView: UIScrollView {

    init() {
        super.init(frame: .zero)

        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardFrameChanged(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)
    }

    /// Creates a new keyboard-avoiding scrollview with the given view configured as content view.
    ///
    /// This initializer adds the content view as a subview and installs the appropriate set of constraints.
    ///
    /// - Parameter contentView: The view to be used as content view.
    convenience init(contentView: UIView) {
        self.init()

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: widthAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Event Handling

private extension LinkKeyboardAvoidingScrollView {

    @objc func keyboardFrameChanged(_ notification: Notification) {
        let userInfo = notification.userInfo

        guard let keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let absoluteFrame = convert(bounds, to: window)
        let intersection = absoluteFrame.intersection(keyboardFrame)

        UIView.animateAlongsideKeyboard(notification) {
            self.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: intersection.height, right: 0)
            self.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: intersection.height, right: 0)
        }
    }

}
