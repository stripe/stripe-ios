//
//  EmbeddedMandateContainerView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/3/24.
//

import Foundation
import UIKit

/// A simple container that holds a mandate text view for the embedded payment element and applies constraints for it to be presented in the `EmbeddedPaymentMethodsView`'s `UIStackView`.
class EmbeddedMandateContainerView: UIView {
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
            mandateView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            mandateView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        if appearance.embeddedPaymentElement.style != .floatingButton {
            self.backgroundColor = appearance.colors.componentBackground
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
