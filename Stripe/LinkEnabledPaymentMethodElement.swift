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
    struct Constants {
        static let spacing: CGFloat = 12
    }

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
        stackView.spacing = Constants.spacing
        stackView.distribution = .equalSpacing
        stackView.isLayoutMarginsRelativeArrangement = true

        return stackView
    }()

    let paymentMethodType: PaymentSheet.PaymentMethodType

    let paymentMethodElement: PaymentMethodElement

    let inlineSignupElement: LinkInlineSignupElement

    init(
        type: PaymentSheet.PaymentMethodType,
        paymentMethodElement: PaymentMethodElement,
        configuration: PaymentSheet.Configuration,
        linkAccount: PaymentSheetLinkAccount?,
        country: String?
    ) {
        self.paymentMethodType = type
        self.paymentMethodElement = paymentMethodElement
        self.inlineSignupElement = LinkInlineSignupElement(
            configuration: configuration,
            linkAccount: linkAccount,
            country: country
        )

        paymentMethodElement.delegate = self
        inlineSignupElement.delegate = self
    }

    func makePaymentOption() -> PaymentOption? {
        guard let params = updateParams(params: .init(type: paymentMethodType)) else {
            return nil
        }

        switch inlineSignupElement.action {
        case .pay(let account):
            return .link(
                option: .withPaymentMethodParams(
                    account: account,
                    paymentMethodParams: params.paymentMethodParams
                )
            )
        case .signupAndPay(let account, let phoneNumber, let legalName):
            return .link(
                option: .signUp(
                    account: account,
                    phoneNumber: phoneNumber,
                    legalName: legalName,
                    paymentMethodParams: params.paymentMethodParams
                )
            )
        case .continueWithoutLink:
            return .new(confirmParams: params)
        case .none:
            return nil
        }
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

    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }

}
