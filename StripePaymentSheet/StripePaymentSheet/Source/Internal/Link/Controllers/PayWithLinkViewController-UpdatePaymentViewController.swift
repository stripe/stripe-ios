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
    func didUpdate(paymentMethod: ConsumerPaymentDetails, confirmationExtras: LinkConfirmationExtras?)
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

        /// Denotes whether we're launching this screen in the confirmation flow with the purpose of collecting any missing billing details.
        /// If that is the case, we will immediately confirm the intent after updating the payment method.
        let isBillingDetailsUpdateFlow: Bool

        private lazy var thisIsYourDefaultLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .bodyEmphasized)
            label.textColor = .linkTextSecondary
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
            callToAction: isBillingDetailsUpdateFlow ? context.callToAction : .custom(title: String.Localized.update_card)
        ) { [weak self] in
            self?.updateCard()
        }

        private lazy var errorLabel: UILabel = {
            return ElementsUI.makeErrorLabel(theme: LinkUI.appearance.asElementsTheme)
        }()

        private lazy var cardEditElement = LinkPaymentMethodFormElement(
            paymentMethod: paymentMethod,
            configuration: makeConfiguration(),
            useCVCPlaceholder: isBillingDetailsUpdateFlow
        )

        private func makeConfiguration() -> PaymentElementConfiguration {
            guard isBillingDetailsUpdateFlow else {
                return context.configuration
            }

            var configuration = context.configuration
            configuration.defaultBillingDetails = configuration.effectiveBillingDetails(for: linkAccount)
            return configuration
        }

        init(
            linkAccount: PaymentSheetLinkAccount,
            context: Context,
            paymentMethod: ConsumerPaymentDetails,
            isBillingDetailsUpdateFlow: Bool
        ) {
            self.linkAccount = linkAccount
            self.intent = context.intent
            self.configuration = context.configuration
            self.configuration.linkPaymentMethodsOnly = true
            self.paymentMethod = paymentMethod
            self.isBillingDetailsUpdateFlow = isBillingDetailsUpdateFlow

            let title: String = isBillingDetailsUpdateFlow ? String.Localized.confirm_payment_details : String.Localized.update_card
            super.init(context: context, navigationTitle: title)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            self.cardEditElement.delegate = self
            view.backgroundColor = .linkSurfacePrimary
            view.directionalLayoutMargins = LinkUI.contentMargins
            errorLabel.isHidden = true

            let stackView = UIStackView(arrangedSubviews: [
                cardEditElement.view,
                errorLabel,
                thisIsYourDefaultLabel,
                updateButton,
            ])

            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.directionalLayoutMargins = LinkUI.contentMargins
            stackView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(stackView)

            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: stackView.topAnchor),
                contentView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            ])

            if !paymentMethod.isDefault || isBillingDetailsUpdateFlow {
                thisIsYourDefaultLabel.isHidden = true
                stackView.setCustomSpacing(LinkUI.largeContentSpacing, after: cardEditElement.view)
            } else {
                stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: thisIsYourDefaultLabel)
            }

            updateButton.update(state: cardEditElement.validationState.isValid ? .enabled : .disabled)
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
                details: .card(
                    expiryDate: params.expiryDate,
                    billingDetails: params.billingDetails,
                    preferredNetwork: params.preferredNetwork
                )
            )

            coordinator?.allowSheetDismissal(false)

            linkAccount.updatePaymentDetails(id: paymentMethod.stripeID, updateParams: updateParams) { [weak self] result in
                guard let self else {
                    return
                }

                switch result {
                case .success(let updatedPaymentDetails):
                    // Updates to CVC only get applied when the intent is confirmed so we manually add them here
                    // instead of including in the /update API call
                    if case .card(let card) = updatedPaymentDetails.details {
                        // If we collected CVC on the previous screen, use that value
                        card.cvc = params.cvc ?? paymentMethod.cvc
                    }

                    var confirmationExtras: LinkConfirmationExtras?
                    if self.isBillingDetailsUpdateFlow {
                        confirmationExtras = .init(billingPhoneNumber: self.isBillingDetailsUpdateFlow ? params.billingDetails.phone : nil)
                    }

                    self.updateButton.update(state: .succeeded, style: nil, callToAction: nil, animated: true) {
                        self.coordinator?.allowSheetDismissal(true)
                        self.delegate?.didUpdate(
                            paymentMethod: updatedPaymentDetails,
                            confirmationExtras: confirmationExtras
                        )
                        _ = self.bottomSheetController?.popContentViewController()
                    }
                case .failure(let error):
                    self.updateErrorLabel(for: error)
                    self.cardEditElement.view.isUserInteractionEnabled = true
                    self.updateButton.update(state: .enabled)
                    coordinator?.allowSheetDismissal(true)
                }
            }
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
