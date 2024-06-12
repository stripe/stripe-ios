//
//  FormHeaderView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/4/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class FormHeaderView: UIView {

    private lazy var label: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: appearance)
        if paymentMethodType == .stripe(.card) {
            label.text = hasASavedCard ? String.Localized.add_card : String.Localized.add_new_card
        } else if paymentMethodType == .stripe(.USBankAccount) {
            label.text = String.Localized.add_us_bank_account
        } else {
            label.text = paymentMethodType.displayName
        }

        return label
    }()

    private lazy var imageView: PaymentMethodTypeImageView? = {
        switch paymentMethodType {
        case .stripe(.card), .stripe(.USBankAccount):
            // Don't show an image on the form header for card and US bank account
            return nil
        default:
            return PaymentMethodTypeImageView(paymentMethodType: paymentMethodType, backgroundColor: appearance.colors.background)
        }
    }()

    private lazy var stackView: UIStackView = {
        let views = [imageView, label].compactMap { $0 }
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.spacing = 12
        return stackView
    }()

    private let paymentMethodType: PaymentSheet.PaymentMethodType
    private let hasASavedCard: Bool // true if the customer has a saved payment method that is type card
    private let appearance: PaymentSheet.Appearance

    init(paymentMethodType: PaymentSheet.PaymentMethodType, hasASavedCard: Bool, appearance: PaymentSheet.Appearance) {
        self.paymentMethodType = paymentMethodType
        self.hasASavedCard = hasASavedCard
        self.appearance = appearance
        super.init(frame: .zero)
        addAndPinSubview(stackView)
        if let imageView {
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 20),
                imageView.heightAnchor.constraint(equalToConstant: 20),
            ])
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
