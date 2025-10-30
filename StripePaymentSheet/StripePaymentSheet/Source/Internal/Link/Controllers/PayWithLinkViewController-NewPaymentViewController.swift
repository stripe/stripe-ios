//
//  PayWithLinkViewController-NewPaymentViewController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

extension PayWithLinkViewController {

    /// For internal SDK use only
    @objc(STP_Internal_NewPaymentViewController)
    final class NewPaymentViewController: BaseViewController {
        struct Constants {
            static let applePayButtonHeight: CGFloat = 48
        }

        let linkAccount: PaymentSheetLinkAccount
        let isAddingFirstPaymentMethod: Bool

        private lazy var errorView: LinkHintMessageView = {
            LinkHintMessageView(message: nil, style: .error)
        }()

        private lazy var confirmButton: ConfirmButton = .makeLinkButton(
            callToAction: context.callToAction,
            showProcessingLabel: context.showProcessingLabel,
            // Use a compact button if we are also displaying the Apple Pay button.
            compact: shouldShowApplePayButton,
            linkAppearance: context.linkAppearance,
            didTapWhenDisabled: didTapWhenDisabled
        ) { [weak self] in
            self?.confirm()
        }

        private lazy var separator = SeparatorLabel(text: String.Localized.or)

        private lazy var applePayButton: PKPaymentButton = {
            let button = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .compatibleAutomatic)
            button.addTarget(self, action: #selector(applePayButtonTapped(_:)), for: .touchUpInside)
            button.cornerRadius = LinkUI.cornerRadius

            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.applePayButtonHeight)
            ])

            return button
        }()

        private lazy var cancelButton: Button? = {
            guard linkAccount.isInSignupFlow && context.launchedFromFlowController else {
                return nil
            }
            let button = Button(
                configuration: .linkPlain(),
                title: context.secondaryButtonLabel
            )
            button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
            return button
        }()

        private lazy var buttonContainer: UIStackView = {
            let vStack = UIStackView(arrangedSubviews: [confirmButton])
            vStack.axis = .vertical
            vStack.spacing = LinkUI.contentSpacing

            if shouldShowApplePayButton {
                vStack.addArrangedSubview(separator)
                vStack.addArrangedSubview(applePayButton)
            }

            if let cancelButton {
                vStack.addArrangedSubview(cancelButton)
            }

            return vStack
        }()

        private lazy var addPaymentMethodVC: AddPaymentMethodViewController = {
            return AddPaymentMethodViewController(
                intent: context.intent,
                elementsSession: context.elementsSession,
                configuration: makeConfiguration(),
                paymentMethodTypes: [.stripe(.card)],
                formCache: .init(), // We don't want to share a form cache with the containing PaymentSheet
                analyticsHelper: context.analyticsHelper,
                isLinkUI: true,
                delegate: self,
                linkAppearance: context.linkAppearance
            )
        }()

        private func makeConfiguration() -> PaymentElementConfiguration {
            var configuration = context.configuration
            configuration.linkPaymentMethodsOnly = true
            configuration.appearance = LinkUI.appearance

            // AddPaymentMethodViewController uses textSecondary for the mandate, but Link uses linkTextTertiary
            configuration.appearance.colors.textSecondary = .linkTextTertiary

            if let primaryColorOverride = context.linkAppearance?.colors?.primary {
                configuration.appearance.colors.primary = primaryColorOverride
            }

            configuration.cardBrandAcceptance = context.elementsSession.linkCardBrandFilteringEnabled ? configuration.cardBrandAcceptance : .all

            let effectiveBillingDetails = configuration.effectiveBillingDetails(for: linkAccount)
            configuration.defaultBillingDetails = effectiveBillingDetails

            return configuration
        }

        #if !os(visionOS)
        private let feedbackGenerator = UINotificationFeedbackGenerator()
        #endif

        private var shouldShowApplePayButton: Bool {
            return (
                isAddingFirstPaymentMethod &&
                context.shouldOfferApplePay
            )
        }

        init(
            linkAccount: PaymentSheetLinkAccount,
            context: Context,
            isAddingFirstPaymentMethod: Bool
        ) {
            self.linkAccount = linkAccount
            self.isAddingFirstPaymentMethod = isAddingFirstPaymentMethod

            let title: String? = isAddingFirstPaymentMethod ? nil : String.Localized.add_a_payment_method
            super.init(context: context, navigationTitle: title)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            addChild(addPaymentMethodVC)

            view.backgroundColor = .linkSurfacePrimary

            addPaymentMethodVC.view.backgroundColor = .clear
            errorView.isHidden = true

            let stackView = UIStackView(arrangedSubviews: [
                addPaymentMethodVC.view,
                errorView,
                buttonContainer,
            ])

            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.directionalLayoutMargins = .insets(top: LinkUI.contentMargins.top, bottom: LinkUI.contentMargins.bottom)
            stackView.alignment = .center
            stackView.translatesAutoresizingMaskIntoConstraints = false

            contentView.addAndPinSubview(stackView, insets: .insets(bottom: LinkUI.appearance.formInsets.bottom))

            NSLayoutConstraint.activate([
                errorView.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: preferredContentMargins.leading),
                errorView.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -preferredContentMargins.trailing),

                addPaymentMethodVC.view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                addPaymentMethodVC.view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

                buttonContainer.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: LinkUI.contentMargins.leading),
                buttonContainer.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -LinkUI.contentMargins.trailing),
            ])

            didUpdate(addPaymentMethodVC)
            stackView.setNeedsLayout()
            stackView.layoutIfNeeded()

        }

        private func didTapWhenDisabled() {
            // Clear any previous confirmation error
            updateErrorLabel(for: nil)

#if !os(visionOS)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
#endif
            addPaymentMethodVC.paymentMethodFormElement.showAllValidationErrors()
        }

        func confirm() {
            updateErrorLabel(for: nil)

            // Dismiss keyboard
            view.endEditing(true)

            if addPaymentMethodVC.selectedPaymentMethodType == .instantDebits {
                didSelectAddBankAccount()
                return
            }

            guard let newPaymentOption = addPaymentMethodVC.paymentOption,
                  case .new(let confirmParams) = newPaymentOption else {
                stpAssertionFailure()
                return
            }

            #if !os(visionOS)
            feedbackGenerator.prepare()
            #endif
            confirmButton.update(state: .processing)
            coordinator?.allowSheetDismissal(false)

            confirmParams.paymentMethodParams.clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadataIfNecessary(analyticsHelper: context.analyticsHelper, intent: context.intent, elementsSession: context.elementsSession)

            linkAccount.createPaymentDetails(
                with: confirmParams.paymentMethodParams,
                isDefault: isAddingFirstPaymentMethod
            ) { [weak self] result in
                guard let self = self else {
                    return
                }

                switch result {
                case .success(let paymentDetails):
                    if case .card(let card) = paymentDetails.details {
                        card.cvc = confirmParams.paymentMethodParams.card?.cvc
                    }

                    let confirmationExtras = LinkConfirmationExtras(
                        // We need to explicitly pass the phone number to the confirm call, since it's not
                        // part of the payment details' billing information.
                        billingPhoneNumber: confirmParams.paymentMethodParams.billingDetails?.phone
                    )

                    guard !context.launchedFromFlowController else {
                        coordinator?.handlePaymentDetailsSelected(paymentDetails, confirmationExtras: confirmationExtras)
                        return
                    }

                    self.coordinator?.confirm(
                        with: self.linkAccount,
                        paymentDetails: paymentDetails,
                        confirmationExtras: confirmationExtras
                    ) { [weak self] result, deferredIntentConfirmationType in
                        let state: ConfirmButton.Status

                        switch result {
                        case .completed:
                            state = .succeeded
                        case .canceled:
                            state = .enabled
                        case .failed(let error):
                            state = .enabled
                            self?.updateErrorLabel(for: error)
                        }

                        #if !os(visionOS)
                        self?.feedbackGenerator.notificationOccurred(.success)
                        #endif
                        self?.confirmButton.update(state: state, animated: true) {
                            self?.coordinator?.allowSheetDismissal(true)
                            if state == .succeeded {
                                self?.coordinator?.finish(withResult: result, deferredIntentConfirmationType: deferredIntentConfirmationType)
                            }
                        }
                    }
                case .failure(let error):
                    #if !os(visionOS)
                    self.feedbackGenerator.notificationOccurred(.error)
                    #endif
                    self.confirmButton.update(state: .enabled, animated: true)
                    self.updateErrorLabel(for: error)
                    self.coordinator?.allowSheetDismissal(true)
                }
            }
        }

        func didSelectAddBankAccount() {
            confirmButton.update(state: .processing)

            coordinator?.startInstantDebits { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    break
                case .failure(let error):
                    switch error {
                    case InstantDebitsOnlyAuthenticationSessionManager.Error.canceled:
                        self.confirmButton.update(state: .enabled)
                    default:
                        self.updateErrorLabel(for: error)
                        self.confirmButton.update(state: .enabled)
                    }
                }
            }
        }

        func updateErrorLabel(for error: Error?) {
            errorView.text = error?.nonGenericDescription
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                self.errorView.setHiddenIfNecessary(error == nil)
            }
        }

        @objc
        func applePayButtonTapped(_ sender: PKPaymentButton) {
            coordinator?.confirmWithApplePay()
        }

        @objc
        func cancelButtonTapped() {
            coordinator?.cancel(shouldReturnToPaymentSheet: true)
        }
    }
}

extension PayWithLinkViewController.NewPaymentViewController: AddPaymentMethodViewControllerDelegate {
    func getWalletHeaders() -> [String] {
        return []
    }

    func didUpdate(_ viewController: AddPaymentMethodViewController) {
        if viewController.selectedPaymentMethodType == .instantDebits {
            confirmButton.update(state: .enabled, callToAction: .add(paymentMethodType: .instantDebits))
        } else {
            confirmButton.update(
                state: viewController.paymentOption != nil ? .enabled : .disabled,
                callToAction: context.callToAction
            )
        }
        updateErrorLabel(for: nil)
    }

    func shouldOfferLinkSignup(_ viewController: AddPaymentMethodViewController) -> Bool {
        return false
    }

}
