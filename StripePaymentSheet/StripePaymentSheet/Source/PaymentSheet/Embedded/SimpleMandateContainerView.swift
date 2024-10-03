//
//  SimpleMandateContainerView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/3/24.
//

import Foundation
import UIKit

class SimpleMandateContainerView: UIView {
    private let mandateView: SimpleMandateTextView

    var attributedText: NSAttributedString? {
        get {
            return mandateView.attributedText
        }

        set {
            mandateView.attributedText = newValue
        }
    }

    init(appearance: PaymentSheet.Appearance) {
        self.mandateView = SimpleMandateTextView(theme: appearance.asElementsTheme)
        super.init(frame: .zero)

        addSubview(mandateView)
        mandateView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mandateView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: PaymentSheetUI.defaultPadding),
            mandateView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -PaymentSheetUI.defaultPadding),
            mandateView.topAnchor.constraint(equalTo: topAnchor),
            mandateView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
