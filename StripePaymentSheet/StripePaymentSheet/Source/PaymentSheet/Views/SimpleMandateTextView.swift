//
//  SimpleMandateTextView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 6/15/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

/// For internal SDK use only
@objc(STP_Internal_SimpleMandateTextView)
class SimpleMandateTextView: UIView {
    private let theme: ElementsAppearance
    var viewDidAppear: Bool = false
    let textView: UITextView = UITextView()
    var attributedText: NSAttributedString? {
        get {
            textView.attributedText.string.isEmpty ? nil : textView.attributedText
        }
        set {
            textView.attributedText = newValue
            // Re-apply textView styling; otherwise certain things like insets get reset
            applyTextViewStyle()
        }
    }

    convenience init(mandateText: NSAttributedString, theme: ElementsAppearance) {
        self.init(theme: theme)
        textView.attributedText = mandateText
    }

    convenience init(mandateText: String, theme: ElementsAppearance) {
        self.init(theme: theme)
        textView.text = mandateText
    }

    required init(theme: ElementsAppearance) {
        self.theme = theme
        super.init(frame: .zero)
        installConstraints()
        applyTextViewStyle()
        self.accessibilityIdentifier = "mandatetextview"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func installConstraints() {
        addAndPinSubview(textView, directionalLayoutMargins: .zero)
    }

    fileprivate func applyTextViewStyle() {
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.font = theme.fonts.caption
        textView.backgroundColor = .clear
        textView.textColor = theme.colors.secondaryText
        textView.adjustsFontForContentSizeCategory = true
        textView.linkTextAttributes = [.foregroundColor: theme.colors.primary]
        // These two lines remove insets that are on UITextViews by default
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .natural
    }
}

extension SimpleMandateTextView: EventHandler {
    func handleEvent(_ event: StripeUICore.STPEvent) {
        if case .viewDidAppear = event {
           viewDidAppear = true
        }
    }
}
