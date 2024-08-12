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
    public lazy var elements: [Element] = { [inlineSignupElement] }()

    struct Constants {
        static let spacing: CGFloat = 12
    }

    weak var delegate: ElementDelegate?

    var view: UIView {
        return stackView
    }

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            inlineSignupElement.view,
        ])
        stackView.axis = .vertical
        stackView.spacing = Constants.spacing
        stackView.distribution = .equalSpacing
        stackView.isLayoutMarginsRelativeArrangement = true

        return stackView
    }()

    let inlineSignupElement: LinkInlineSignupElement

    init(
        configuration: PaymentSheet.Configuration,
        linkAccount: PaymentSheetLinkAccount?,
        country: String?,
        showCheckbox: Bool
    ) {
        self.inlineSignupElement = LinkInlineSignupElement(
            configuration: configuration,
            linkAccount: linkAccount,
            country: country,
            showCheckbox: showCheckbox
        )

        inlineSignupElement.delegate = self
    }

    func makePaymentOption(intentConfirmParams params: IntentConfirmParams) -> PaymentOption? {
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

extension LinkEnabledPaymentMethodElement: ElementDelegate {

    func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }

    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }
}
