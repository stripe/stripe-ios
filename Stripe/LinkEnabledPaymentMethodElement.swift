//
//  LinkEnabledPaymentMethodElement.swift
//  StripeiOS
//
//  Created by Ramon Torres on 2/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

final class LinkEnabledPaymentMethodElement: Element {

    weak var delegate: ElementDelegate?

    var view: UIView {
        return stackView
    }

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            paymentMethodElement.view,
            inlineSignupElement.view
        ])
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.distribution = .equalSpacing
        return stackView
    }()

    let paymentMethodType: STPPaymentMethodType

    let paymentMethodElement: PaymentMethodElement

    let inlineSignupElement: LinkInlineSignupElement

    init(
        type: STPPaymentMethodType,
        paymentMethodElement: PaymentMethodElement,
        configuration: PaymentSheet.Configuration
    ) {
        self.paymentMethodType = type
        self.paymentMethodElement = paymentMethodElement
        self.inlineSignupElement = .init(configuration: configuration)

        paymentMethodElement.delegate = self
        inlineSignupElement.delegate = self
    }

    func makePaymentOption() -> PaymentOption? {
        guard let params = updateParams(params: .init(type: paymentMethodType)) else {
            return nil
        }

        if inlineSignupElement.isChecked,
           let (linkAccount, phoneNumber) = inlineSignupElement.signupDetails {
            return .link(account: linkAccount, option: .forNewAccount(phoneNumber: phoneNumber, paymentMethodParams: params.paymentMethodParams))
        }

        return .new(confirmParams: params)
    }

}

extension LinkEnabledPaymentMethodElement: PaymentMethodElement {

    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        return paymentMethodElement.updateParams(params: params)
    }

}

extension LinkEnabledPaymentMethodElement: ElementDelegate {

    func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }

    func didFinishEditing(element: Element) {
        delegate?.didFinishEditing(element: self)
    }

}
