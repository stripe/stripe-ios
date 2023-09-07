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
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = theme.fonts.caption
        label.textColor = theme.colors.secondaryText
        label.numberOfLines = 0
        return label
    }()

    init(mandateText: String, theme: ElementsUITheme = .default) {
        self.theme = theme
        super.init(frame: .zero)
        label.text = mandateText
        installConstraints()
        self.accessibilityIdentifier = "mandatetextview"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func installConstraints() {
        addAndPinSubview(label)
    }
}

extension SimpleMandateTextView: EventHandler {
    func handleEvent(_ event: StripeUICore.STPEvent) {
        if case .viewDidAppear = event {
           viewDidAppear = true
        }
    }
}
