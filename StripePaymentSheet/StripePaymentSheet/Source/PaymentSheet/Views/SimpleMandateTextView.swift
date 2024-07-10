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
    private let theme: ElementsUITheme
    var viewDidAppear: Bool = false
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.font = theme.fonts.caption
        textView.backgroundColor = .clear
        textView.textColor = theme.colors.secondaryText
        textView.linkTextAttributes = [.foregroundColor: theme.colors.primary]
        // These two lines remove insets that are on UITextViews by default
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()

    convenience init(mandateText: NSAttributedString, theme: ElementsUITheme) {
        self.init(theme: theme)
        textView.attributedText = mandateText
    }

    convenience init(mandateText: String, theme: ElementsUITheme) {
        self.init(theme: theme)
        textView.text = mandateText
    }

    required init(theme: ElementsUITheme) {
        self.theme = theme
        super.init(frame: .zero)
        installConstraints()
        self.accessibilityIdentifier = "mandatetextview"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func installConstraints() {
        addAndPinSubview(textView)
    }
}

extension SimpleMandateTextView: EventHandler {
    func handleEvent(_ event: StripeUICore.STPEvent) {
        if case .viewDidAppear = event {
           viewDidAppear = true
        }
    }
}
