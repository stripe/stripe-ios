//
//  UIViewController+Stripe_KeyboardAvoiding.swift
//  StripeiOS
//
//  Created by Jack Flintermann on 4/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

typealias STPKeyboardFrameBlock = (CGRect, UIView?) -> Void

// This is a private class that is only a UIViewController subclass by virtue of the fact
// that that makes it easier to attach to another UIViewController as a child.
class STPKeyboardDetectingViewController: UIViewController {
    var lastKeyboardFrame = CGRect.zero
    weak var lastResponder: UIView?
    var keyboardFrameBlock: STPKeyboardFrameBlock?
    weak var managedScrollView: UIScrollView?
    var currentBottomInsetChange: CGFloat = 0.0

    init(
        keyboardFrameBlock block: STPKeyboardFrameBlock?,
        scrollView: UIScrollView?
    ) {
        keyboardFrameBlock = block
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textFieldWillBeginEditing(_:)),
            name: UITextField.textDidBeginEditingNotification,
            object: nil
        )
        managedScrollView = scrollView
        currentBottomInsetChange = 0
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func loadView() {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.autoresizingMask = []
        self.view = view
    }

    @objc func textFieldWillBeginEditing(_ notification: Notification) {
        guard let textField = notification.object as? UITextField, let parentView = parent?.view,
            textField.isDescendant(of: parentView)
        else {
            return
        }
        if let keyboardFrameBlock = keyboardFrameBlock,
            textField != lastResponder && !lastKeyboardFrame.isEmpty
        {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: .curveEaseOut,
                animations: {
                    keyboardFrameBlock(self.lastKeyboardFrame, textField)
                }
            )
        }
    }

    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        // As of iOS 8, this all takes place inside the necessary animation block
        // https://twitter.com/SmileyKeith/status/684100833823174656
        guard
            var keyboardFrame =
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
                .cgRectValue,
            let window = view.window
        else {
            return
        }
        keyboardFrame = window.convert(keyboardFrame, from: nil)

        if managedScrollView != nil {
            if !lastKeyboardFrame.equalTo(keyboardFrame) {
                let responder = parent?.view.stp_findFirstResponder()
                lastResponder = responder
                doKeyboardChangeAnimation(withNewFrame: keyboardFrame)
            }
        }
    }

    func doKeyboardChangeAnimation(withNewFrame keyboardFrame: CGRect) {
        lastKeyboardFrame = keyboardFrame

        if let managedScrollView = managedScrollView {
            let scrollView = managedScrollView
            let scrollViewSuperView = managedScrollView.superview

            var contentInsets = scrollView.contentInset
            var scrollIndicatorInsets: UIEdgeInsets = .zero
            #if !TARGET_OS_MACCATALYST
                scrollIndicatorInsets = scrollView.verticalScrollIndicatorInsets
            #else
                scrollIndicatorInsets = scrollView.scrollIndicatorInsets
            #endif

            let windowFrame = scrollViewSuperView?.convert(
                scrollViewSuperView?.frame ?? CGRect.zero,
                to: nil
            )

            let bottomIntersection = windowFrame?.intersection(keyboardFrame)
            let bottomInsetDelta =
                (bottomIntersection?.size.height ?? 0.0) - currentBottomInsetChange
            contentInsets.bottom += bottomInsetDelta
            scrollIndicatorInsets.bottom += bottomInsetDelta
            currentBottomInsetChange += bottomInsetDelta
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = scrollIndicatorInsets
        }

        if let keyboardFrameBlock = keyboardFrameBlock {
            keyboardFrameBlock(keyboardFrame, lastResponder)
        }
    }

    required init?(
        coder aDecoder: NSCoder
    ) {
        super.init(coder: aDecoder)
    }
}
