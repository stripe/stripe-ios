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

        // Match the bottom spacing of `CardDetailsEditView`.
        stackView.layoutMargins = .init(top: 0, left: 0, bottom: STPFormView.interSectionSpacing, right: 0)

        return stackView
    }()

    let paymentMethodType: STPPaymentMethodType

    let paymentMethodElement: PaymentMethodElement

    let inlineSignupElement: LinkInlineSignupElement

    init(
        type: STPPaymentMethodType,
        paymentMethodElement: PaymentMethodElement,
        configuration: PaymentSheet.Configuration,
        linkAccount: PaymentSheetLinkAccount?
    ) {
        self.paymentMethodType = type
        self.paymentMethodElement = paymentMethodElement
        self.inlineSignupElement = .init(
            configuration: configuration,
            linkAccount: linkAccount
        )

        paymentMethodElement.delegate = self
        inlineSignupElement.delegate = self
    }

    func makePaymentOption() -> PaymentOption? {
        guard let params = updateParams(params: .init(type: paymentMethodType)) else {
            return nil
        }

        if inlineSignupElement.isChecked {
            switch inlineSignupElement.action {
            case .pay(let account):
                return .link(
                    account: account,
                    option: .withPaymentMethodParams(paymentMethodParams: params.paymentMethodParams)
                )
            case .signupAndPay(let account, let phoneNumber):
                return .link(
                    account: account,
                    option: .forNewAccount(
                        phoneNumber: phoneNumber,
                        paymentMethodParams: params.paymentMethodParams
                    )
                )
            default:
                return nil
            }
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
