//
//  LinkKeyboardAvoidingScrollView.swift
//  StripeiOS
//
//  Created by Ramon Torres on 1/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

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
