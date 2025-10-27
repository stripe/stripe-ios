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

        private let linkAppearance: LinkAppearance?

        private lazy var thisIsYourDefaultView: LinkHintMessageView = {
            let message = STPLocalizedString(
                "This is your default",
                "Text of a label indicating that a payment method is the default."
            )
            return LinkHintMessageView(message: message, style: .outlined)
        }()

        private lazy var updateButton: ConfirmButton = .makeLinkButton(
            callToAction: isBillingDetailsUpdateFlow ? context.callToAction : .custom(title: String.Localized.update_card),
            showProcessingLabel: context.showProcessingLabel,
            linkAppearance: context.linkAppearance,
            didTapWhenDisabled: didTapWhenDisabled
        ) { [weak self] in
            self?.updatePaymentMethod()
        }

        private func didTapWhenDisabled() {
            // Clear any previous confirmation error
            updateErrorLabel(for: nil)

#if !os(visionOS)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
#endif
            paymentMethodEditElement.showAllValidationErrors()
        }

        private lazy var errorView: LinkHintMessageView = {
            LinkHintMessageView(message: nil, style: .error)
        }()

        private lazy var paymentMethodEditElement = LinkPaymentMethodFormElement(
            paymentMethod: paymentMethod,
            configuration: makeConfiguration(),
            isBillingDetailsUpdateFlow: isBillingDetailsUpdateFlow,
            linkAppearance: linkAppearance
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
            isBillingDetailsUpdateFlow: Bool,
            linkAppearance: LinkAppearance? = nil
        ) {
            self.linkAccount = linkAccount
            self.intent = context.intent
            self.configuration = context.configuration
            self.configuration.linkPaymentMethodsOnly = true
            self.paymentMethod = paymentMethod
            self.isBillingDetailsUpdateFlow = isBillingDetailsUpdateFlow
            self.linkAppearance = linkAppearance

            let title: String = isBillingDetailsUpdateFlow ? String.Localized.confirm_payment_details : String.Localized.update_card
            super.init(context: context, navigationTitle: title)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            self.paymentMethodEditElement.delegate = self
            view.backgroundColor = .linkSurfacePrimary
            view.directionalLayoutMargins = LinkUI.contentMargins
            errorView.isHidden = true

            let stackView = UIStackView(arrangedSubviews: [
                paymentMethodEditElement.view,
                thisIsYourDefaultView,
                errorView,
                updateButton,
            ])

            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.directionalLayoutMargins = LinkUI.contentMargins
            stackView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addAndPinSubview(stackView, insets: .insets(bottom: LinkUI.bottomInset))

            if !paymentMethod.isDefault || isBillingDetailsUpdateFlow {
                thisIsYourDefaultView.isHidden = true
            }

            updateButton.update(state: paymentMethodEditElement.validationState.isValid ? .enabled : .disabled)

        }

        func updatePaymentMethod() {
            updateErrorLabel(for: nil)

            guard let params = paymentMethodEditElement.params else {
                stpAssertionFailure("Params are expected to be not `nil` when `updatePaymentMethod()` is called.")
                return
            }

            guard let updateDetails = createUpdateDetails(for: params) else {
                stpAssertionFailure("Update details are expected to be not `nil` when `updatePaymentMethod()` is called.")
                return
            }

            paymentMethodEditElement.view.endEditing(true)
            paymentMethodEditElement.view.isUserInteractionEnabled = false
            updateButton.update(state: .processing)

            // When updating a payment method that is not the default and you send isDefault=false to the server you get
            // "Can't unset payment details when it's not the default", so send nil instead of false
            let updateParams = UpdatePaymentDetailsParams(
                isDefault: params.setAsDefault ? true : nil,
                details: updateDetails
            )

            let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadataIfNecessary(analyticsHelper: context.analyticsHelper, intent: context.intent, elementsSession: context.elementsSession)

            coordinator?.allowSheetDismissal(false)

            linkAccount.updatePaymentDetails(id: paymentMethod.stripeID, updateParams: updateParams, clientAttributionMetadata: clientAttributionMetadata) { [weak self] result in
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

                    self.updateButton.update(state: .succeeded, callToAction: nil, animated: true) {
                        self.coordinator?.allowSheetDismissal(true)
                        self.delegate?.didUpdate(
                            paymentMethod: updatedPaymentDetails,
                            confirmationExtras: confirmationExtras
                        )
                        _ = self.bottomSheetController?.popContentViewController()
                    }
                case .failure(let error):
                    self.updateErrorLabel(for: error)
                    self.paymentMethodEditElement.view.isUserInteractionEnabled = true
                    self.updateButton.update(state: .enabled)
                    coordinator?.allowSheetDismissal(true)
                }
            }
        }

        func updateErrorLabel(for error: Error?) {
            errorView.text = error?.nonGenericDescription
            errorView.setHiddenIfNecessary(error == nil)
        }

        private func createUpdateDetails(for params: LinkPaymentMethodFormElement.Params) -> UpdatePaymentDetailsParams.DetailsType? {
            switch paymentMethod.type {
            case .card:
                return .card(
                    expiryDate: params.expiryDate,
                    billingDetails: params.billingDetails,
                    preferredNetwork: params.preferredNetwork
                )
            case .bankAccount:
                return .bankAccount(billingDetails: params.billingDetails)
            case .unparsable:
                return nil
            }
        }
    }

}

extension PayWithLinkViewController.UpdatePaymentViewController: ElementDelegate {

    func didUpdate(element: Element) {
        updateErrorLabel(for: nil)
        updateButton.update(state: paymentMethodEditElement.validationState.isValid ? .enabled : .disabled)
    }

    func continueToNextField(element: Element) {
        updateButton.update(state: paymentMethodEditElement.validationState.isValid ? .enabled : .disabled)
    }

}
