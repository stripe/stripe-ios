//
//  LinkEnabledPaymentMethodElement.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 2/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

final class LinkEnabledPaymentMethodElement: ContainerElement {
    public lazy var elements: [Element] = { [paymentMethodElement, inlineSignupElement] }()

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
            inlineSignupElement.view,
        ])
        stackView.axis = .vertical
        stackView.spacing = Constants.spacing
        stackView.distribution = .equalSpacing
        stackView.isLayoutMarginsRelativeArrangement = true

        return stackView
    }()

    let paymentMethodType: STPPaymentMethodType

    let paymentMethodElement: PaymentMethodElement

    let inlineSignupElement: LinkInlineSignupElement

    init(
        type: STPPaymentMethodType,
        paymentMethodElement: PaymentMethodElement,
        configuration: PaymentSheet.Configuration,
        linkAccount: PaymentSheetLinkAccount?,
        country: String?,
        showCheckbox: Bool
    ) {
        self.paymentMethodType = type
        self.paymentMethodElement = paymentMethodElement
        self.inlineSignupElement = LinkInlineSignupElement(
            configuration: configuration,
            linkAccount: linkAccount,
            country: country,
            showCheckbox: showCheckbox
        )

        paymentMethodElement.delegate = self
        inlineSignupElement.delegate = self
    }

    func makePaymentOption(intent: Intent) -> PaymentOption? {
        guard let params = updateParams(params: .init(type: .stripe(paymentMethodType))) else {
            return nil
        }
        params.setAllowRedisplay(for: intent.elementsSession.savePaymentMethodConsentBehavior())

        switch inlineSignupElement.action {
        case .signupAndPay(let account, let phoneNumber, let legalName):
            return .link(
                option: .signUp(
                    account: account,
                    phoneNumber: phoneNumber,
                    consentAction: inlineSignupElement.viewModel.consentAction,
                    legalName: legalName,
                    intentConfirmParams: params
                )
            )
        case .continueWithoutLink:
            return .new(confirmParams: params)
        case .none:
            // Link is optional when in textFieldOnly mode
            if inlineSignupElement.viewModel.mode != .checkbox {
                return .new(confirmParams: params)
            }
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
