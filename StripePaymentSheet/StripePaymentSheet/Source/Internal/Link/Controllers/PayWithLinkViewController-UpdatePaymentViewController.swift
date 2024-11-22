//
//  PayWithLinkViewController-UpdatePaymentViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

protocol UpdatePaymentViewControllerDelegate: AnyObject {
    func didUpdate(paymentMethod: ConsumerPaymentDetails)
}

extension PayWithLinkViewController {

    /// For internal SDK use only
    @objc(STP_Internal_UpdatePaymentViewController)
    final class UpdatePaymentViewController: BaseViewController {
        weak var delegate: UpdatePaymentViewControllerDelegate?
        let linkAccount: PaymentSheetLinkAccount
        let intent: Intent
        var configuration: PaymentElementConfiguration
        let paymentMethod: ConsumerPaymentDetails

        private let titleLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .title)
            label.textColor = .linkPrimaryText
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = String.Localized.update_card
            return label
        }()

        private let thisIsYourDefaultLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .bodyEmphasized)
            label.textColor = .linkSecondaryText
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = STPLocalizedString(
                "This is your default",
                "Text of a label indicating that a payment method is the default."
            )
            return label
        }()

        private lazy var updateButton: ConfirmButton = .makeLinkButton(
            callToAction: .custom(title: String.Localized.update_card)
        ) { [weak self] in
            self?.updateCard()
        }

        private lazy var cancelButton: Button = {
            let button = Button(configuration: .linkSecondary(), title: String.Localized.cancel)
            button.addTarget(self, action: #selector(didSelectCancel), for: .touchUpInside)
            button.adjustsFontForContentSizeCategory = true
            return button
        }()

        private lazy var errorLabel: UILabel = {
            return ElementsUI.makeErrorLabel(theme: LinkUI.appearance.asElementsTheme)
        }()

        private lazy var cardEditElement = LinkCardEditElement(
            paymentMethod: paymentMethod,
            configuration: configuration)

        init(linkAccount: PaymentSheetLinkAccount, context: Context, paymentMethod: ConsumerPaymentDetails) {
            self.linkAccount = linkAccount
            self.intent = context.intent
            self.configuration = context.configuration
            self.configuration.linkPaymentMethodsOnly = true
            self.paymentMethod = paymentMethod
            super.init(context: context)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            self.cardEditElement.delegate = self
            view.backgroundColor = .linkBackground
            view.directionalLayoutMargins = LinkUI.contentMargins
            errorLabel.isHidden = true

            let stackView = UIStackView(arrangedSubviews: [
                titleLabel,
                cardEditElement.view,
                errorLabel,
                thisIsYourDefaultLabel,
                updateButton,
                cancelButton,
            ])

            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: titleLabel)
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.directionalLayoutMargins = LinkUI.contentMargins

            let scrollView = LinkKeyboardAvoidingScrollView(contentView: stackView)
            #if !os(visionOS)
            scrollView.keyboardDismissMode = .interactive
            #endif

            contentView.addAndPinSubview(scrollView)

            if !paymentMethod.isDefault {
                thisIsYourDefaultLabel.isHidden = true
                stackView.setCustomSpacing(LinkUI.largeContentSpacing, after: cardEditElement.view)
            } else {
                stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: thisIsYourDefaultLabel)
            }

            updateButton.update(state: .disabled)
        }

        func updateCard() {
            updateErrorLabel(for: nil)

            guard let params = cardEditElement.params else {
                stpAssertionFailure("Params are expected to be not `nil` when `updateCard()` is called.")
                return
            }

            cardEditElement.view.endEditing(true)
            cardEditElement.view.isUserInteractionEnabled = false
            updateButton.update(state: .processing)

            // When updating a card that is not the default and you send isDefault=false to the server you get
            // "Can't unset payment details when it's not the default", so send nil instead of false
            let updateParams = UpdatePaymentDetailsParams(
                isDefault: params.setAsDefault ? true : nil,
                details: .card(expiryDate: params.expiryDate, billingDetails: params.billingDetails)
            )

            linkAccount.updatePaymentDetails(id: paymentMethod.stripeID, updateParams: updateParams) { [weak self] result in
                switch result {
                case .success(let updatedPaymentDetails):
                    // Updates to CVC only get applied when the intent is confirmed so we manually add them here
                    // instead of including in the /update API call
                    if case .card(let card) = updatedPaymentDetails.details {
                        card.cvc = params.cvc
                    }

                    self?.updateButton.update(state: .succeeded, style: nil, callToAction: nil, animated: true) {
                        self?.delegate?.didUpdate(paymentMethod: updatedPaymentDetails)
                        self?.navigationController?.popViewController(animated: true)
                    }

                case .failure(let error):
                    self?.updateErrorLabel(for: error)
                    self?.cardEditElement.view.isUserInteractionEnabled = true
                    self?.updateButton.update(state: .enabled)
                }
            }
        }

        @objc func didSelectCancel() {
            self.navigationController?.popViewController(animated: true)
        }

        func updateErrorLabel(for error: Error?) {
            errorLabel.text = error?.nonGenericDescription
            errorLabel.setHiddenIfNecessary(error == nil)
        }

    }

}

extension PayWithLinkViewController.UpdatePaymentViewController: ElementDelegate {

    func didUpdate(element: Element) {
        updateErrorLabel(for: nil)
        updateButton.update(state: cardEditElement.validationState.isValid ? .enabled : .disabled)
    }

    func continueToNextField(element: Element) {
        updateButton.update(state: cardEditElement.validationState.isValid ? .enabled : .disabled)
    }

}
