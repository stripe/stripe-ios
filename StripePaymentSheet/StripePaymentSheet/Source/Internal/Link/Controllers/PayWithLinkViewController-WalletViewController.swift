//
//  PayWithLinkViewController-WalletViewController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 10/27/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import PassKit
import SafariServices
import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PayWithLinkViewController {

    final class WalletViewController: BaseViewController {
        struct Constants {
            static let applePayButtonHeight: CGFloat = 48
        }

        let linkAccount: PaymentSheetLinkAccount

        let viewModel: WalletViewModel

        private lazy var paymentPicker: LinkPaymentMethodPicker = {
            let paymentPicker = LinkPaymentMethodPicker()
            paymentPicker.delegate = self
            paymentPicker.dataSource = self
            paymentPicker.supportedPaymentMethodTypes = viewModel.supportedPaymentMethodTypes
            paymentPicker.selectedIndex = viewModel.selectedPaymentMethodIndex
            paymentPicker.billingDetails = context.configuration.defaultBillingDetails
            paymentPicker.billingDetailsCollectionConfiguration = context.configuration.billingDetailsCollectionConfiguration
            return paymentPicker
        }()

        private lazy var instantDebitMandateView = LinkInstantDebitMandateView(delegate: self)

        private lazy var confirmButton = ConfirmButton.makeLinkButton(
            callToAction: viewModel.confirmButtonCallToAction,
            compact: viewModel.shouldUseCompactConfirmButton
        ) { [weak self] in
            guard let self else {
                return
            }

            let confirmationExtras = LinkConfirmationExtras(
                billingPhoneNumber: self.makeEffectiveBillingDetails().phone
            )
            self.confirm(confirmationExtras: confirmationExtras)
        }

        private lazy var cancelButton: Button = {
            let button = Button(
                configuration: viewModel.cancelButtonConfiguration,
                title: String.Localized.pay_another_way
            )
            button.addTarget(self, action: #selector(cancelButtonTapped(_:)), for: .touchUpInside)
            return button
        }()

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

        private lazy var cvcElement: TextFieldElement = {
            let configuration = TextFieldElement.CVCConfiguration(cardBrandProvider: {
                [weak self] in
                    return self?.viewModel.cardBrand ?? .unknown
            })

            return TextFieldElement(configuration: configuration, theme: LinkUI.appearance.asElementsTheme)
        }()

        private lazy var expiryDateElement: TextFieldElement = {
            let configuration = TextFieldElement.ExpiryDateConfiguration()
            return TextFieldElement(configuration: configuration, theme: LinkUI.appearance.asElementsTheme)
        }()

        private lazy var expiredCardNoticeView: LinkNoticeView = {
            let noticeView = LinkNoticeView(type: .error)
            noticeView.text = viewModel.noticeText
            return noticeView
        }()

        private lazy var cardDetailsRecollectionSection: SectionElement = {
            let sectionElement = SectionElement(
                elements: [
                    SectionElement.MultiElementRow([expiryDateElement, cvcElement], theme: LinkUI.appearance.asElementsTheme)
                ], theme: LinkUI.appearance.asElementsTheme
            )
            sectionElement.delegate = self
            return sectionElement
        }()

        private lazy var paymentPickerContainerView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                paymentPicker,
                instantDebitMandateView,
                expiredCardNoticeView,
            ])
            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            return stackView
        }()

        private lazy var errorLabel: UILabel = {
            let label = ElementsUI.makeErrorLabel(theme: LinkUI.appearance.asElementsTheme)
            label.textAlignment = .center
            label.isHidden = true
            return label
        }()

        private lazy var containerView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                paymentPickerContainerView,
                cardDetailsRecollectionSection.view,
                errorLabel,
                confirmButton,
            ])
            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: paymentPickerContainerView)
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: cardDetailsRecollectionSection.view)
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.directionalLayoutMargins = preferredContentMargins
            return stackView
        }()

        private var billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration {
            context.configuration.billingDetailsCollectionConfiguration
        }

        #if !os(visionOS)
        private let feedbackGenerator = UINotificationFeedbackGenerator()
        #endif

        init(
            linkAccount: PaymentSheetLinkAccount,
            context: Context,
            paymentMethods: [ConsumerPaymentDetails]
        ) {
            self.linkAccount = linkAccount
            self.viewModel = WalletViewModel(linkAccount: linkAccount, context: context, paymentMethods: paymentMethods)
            super.init(context: context)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            updateUI(animated: false)
            viewModel.delegate = self
        }

        func setupUI() {
            if viewModel.shouldShowApplePayButton {
                containerView.addArrangedSubview(separator)
                containerView.addArrangedSubview(applePayButton)
            }

            containerView.addArrangedSubview(cancelButton)

            let scrollView = LinkKeyboardAvoidingScrollView(contentView: containerView)
            #if !os(visionOS)
            scrollView.keyboardDismissMode = .interactive
            #endif

            contentView.addAndPinSubview(scrollView)

            // If the initially selected payment method is not supported, we should automatically
            // expand the payment picker to hint the user to pick another payment method.
            if !viewModel.selectedPaymentMethodIsSupported {
                paymentPicker.setExpanded(true, animated: false)
            }
        }

        func updateUI(animated: Bool) {
            if !viewModel.shouldRecollectCardCVC && !viewModel.shouldRecollectCardExpiryDate {
                cardDetailsRecollectionSection.view.endEditing(true)
            }

            paymentPickerContainerView.toggleArrangedSubview(
                instantDebitMandateView,
                shouldShow: viewModel.shouldShowInstantDebitMandate,
                animated: animated
            )

            expiredCardNoticeView.text = viewModel.noticeText
            containerView.toggleArrangedSubview(
                expiredCardNoticeView,
                shouldShow: viewModel.shouldShowNotice,
                animated: animated
            )

            containerView.toggleArrangedSubview(
                cardDetailsRecollectionSection.view,
                shouldShow: viewModel.shouldShowRecollectionSection,
                animated: animated
            )

            UIView.performWithoutAnimation {
                expiryDateElement.view.setHiddenIfNecessary(!viewModel.shouldRecollectCardExpiryDate)
                cvcElement.view.setHiddenIfNecessary(!viewModel.shouldRecollectCardCVC)
                cardDetailsRecollectionSection.view.layoutIfNeeded()
            }

            confirmButton.update(
                state: viewModel.confirmButtonStatus,
                callToAction: viewModel.confirmButtonCallToAction
            )
        }

        func updateErrorLabel(for error: Error?) {
            errorLabel.text = error?.nonGenericDescription
            containerView.toggleArrangedSubview(errorLabel, shouldShow: error != nil, animated: true)
        }

        func confirm(confirmationExtras: LinkConfirmationExtras = LinkConfirmationExtras()) {
            guard let paymentDetails = viewModel.selectedPaymentMethod else {
                stpAssertionFailure("`confirm()` called without a selected payment method")
                return
            }

            guard canConfirmWith(paymentDetails) else {
                handleIncompleteBillingDetails(for: paymentDetails, with: confirmationExtras)
                return
            }

            let confirmWithPaymentDetails: (ConsumerPaymentDetails) -> Void = { [self] paymentDetails in
                if viewModel.shouldRecollectCardCVC {
                    if case let .card(card) = paymentDetails.details {
                        card.cvc = viewModel.cvc
                    }
                }

                confirm(for: context.intent, with: paymentDetails, confirmationExtras: confirmationExtras)
            }

            if viewModel.shouldRecollectCardExpiryDate {
                confirmButton.update(state: .processing)

                viewModel.updateExpiryDate { [weak self] result in
                    switch result {
                    case .success(let paymentDetails):
                        confirmWithPaymentDetails(paymentDetails)
                    case .failure(let error):
                        let alertController = UIAlertController(
                            title: nil,
                            message: error.localizedDescription,
                            preferredStyle: .alert
                        )
                        alertController.addAction(.init(title: String.Localized.ok, style: .default))
                        self?.present(alertController, animated: true)
                        self?.confirmButton.update(state: .enabled)
                    }
                }
            } else {
                confirmWithPaymentDetails(paymentDetails)
            }
        }

        /// Returns whether the provided `paymentDetails` contains all the required billing details.
        private func canConfirmWith(_ paymentDetails: ConsumerPaymentDetails) -> Bool {
            let paymentDetailsAreSupported = paymentDetails.supports(
                billingDetailsCollectionConfiguration,
                in: linkAccount.currentSession
            )

            return paymentDetailsAreSupported
        }

        private func handleIncompleteBillingDetails(
            for paymentDetails: ConsumerPaymentDetails,
            with confirmationExtras: LinkConfirmationExtras
        ) {
            // Fill in missing fields with default values from the provided billing details and
            // from the Link account.
            let effectiveBillingDetails = makeEffectiveBillingDetails()

            let effectivePaymentDetails = paymentDetails.update(
                with: effectiveBillingDetails,
                basedOn: billingDetailsCollectionConfiguration
            )

            let hasRequiredBillingDetailsNow = effectivePaymentDetails.supports(
                billingDetailsCollectionConfiguration,
                in: linkAccount.currentSession
            )

            if hasRequiredBillingDetailsNow {
                // We have filled in all the missing fields. Now, update the payment details and confirm the intent.
                viewModel.updateBillingDetails(
                    paymentMethodID: paymentDetails.stripeID,
                    billingAddress: effectivePaymentDetails.billingAddress,
                    billingEmailAddress: effectiveBillingDetails.email
                ) { [weak self] _ in
                    // We need to pass the billing phone number explicitly, since it's not part of the billing details.
                    let confirmationExtras = LinkConfirmationExtras(
                        billingPhoneNumber: effectiveBillingDetails.phone
                    )
                    self?.confirm(confirmationExtras: confirmationExtras)
                }
            } else {
                // We're still missing fields. Prompt the user to fill them in.
                collectRemainingBillingDetailsAndConfirm(for: effectivePaymentDetails)
            }
        }

        private func makeEffectiveBillingDetails() -> PaymentSheet.BillingDetails {
            return context.configuration.effectiveBillingDetails(for: linkAccount)
        }

        func confirm(
            for intent: Intent,
            with paymentDetails: ConsumerPaymentDetails,
            confirmationExtras: LinkConfirmationExtras?
        ) {
            view.endEditing(true)

            #if !os(visionOS)
            feedbackGenerator.prepare()
            #endif
            updateErrorLabel(for: nil)
            confirmButton.update(state: .processing)

            coordinator?.confirm(
                with: linkAccount,
                paymentDetails: paymentDetails,
                confirmationExtras: confirmationExtras
            ) { [weak self] result, deferredIntentConfirmationType in
                switch result {
                case .completed:
                    #if !os(visionOS)
                    self?.feedbackGenerator.notificationOccurred(.success)
                    #endif
                    self?.confirmButton.update(state: .succeeded, animated: true) {
                        self?.coordinator?.finish(withResult: result, deferredIntentConfirmationType: deferredIntentConfirmationType)
                    }
                case .canceled:
                    self?.confirmButton.update(state: .enabled)
                case .failed(let error):
                    #if !os(visionOS)
                    self?.feedbackGenerator.notificationOccurred(.error)
                    #endif
                    self?.updateErrorLabel(for: error)
                    self?.confirmButton.update(state: .enabled)
                }
            }
        }

        @objc
        func applePayButtonTapped(_ sender: PKPaymentButton) {
            coordinator?.confirmWithApplePay()
        }

        @objc
        func cancelButtonTapped(_ sender: Button) {
            coordinator?.cancel()
        }

    }

}

private extension PayWithLinkViewController.WalletViewController {

    func removePaymentMethod(at index: Int) {
        let paymentMethod = viewModel.paymentMethods[index]

        let alertTitle: String = {
            switch paymentMethod.details {
            case .card:
                return STPLocalizedString(
                    "Are you sure you want to remove this card?",
                    "Title of confirmation prompt when removing a saved card."
                )
            case .bankAccount:
                return STPLocalizedString(
                    "Are you sure you want to remove this linked account?",
                    "Title of confirmation prompt when removing a linked bank account."
                )
            case .unparsable:
                return ""
            }
        }()

        let alertController = UIAlertController(
            title: alertTitle,
            message: nil,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(
            title: String.Localized.cancel,
            style: .cancel
        ))

        alertController.addAction(UIAlertAction(
            title: String.Localized.remove,
            style: .destructive,
            handler: { _ in
                self.paymentPicker.showLoader(at: index)

                self.viewModel.deletePaymentMethod(at: index) { result in
                    switch result {
                    case .success:
                        self.paymentPicker.removePaymentMethod(at: index, animated: true)
                    case .failure:
                        break
                    }

                    self.paymentPicker.hideLoader(at: index)
                }
            }
        ))

        present(alertController, animated: true)
    }

    func updatePaymentMethod(at index: Int) {
        let paymentMethod = viewModel.paymentMethods[index]
        let updatePaymentMethodVC = PayWithLinkViewController.UpdatePaymentViewController(
            linkAccount: linkAccount,
            context: context,
            paymentMethod: paymentMethod,
            isBillingDetailsUpdateFlow: false
        )
        updatePaymentMethodVC.delegate = self

        navigationController?.pushViewController(updatePaymentMethodVC, animated: true)
    }

    func collectRemainingBillingDetailsAndConfirm(for paymentMethod: ConsumerPaymentDetails) {
        let updatePaymentMethodVC = PayWithLinkViewController.UpdatePaymentViewController(
            linkAccount: linkAccount,
            context: context,
            paymentMethod: paymentMethod,
            isBillingDetailsUpdateFlow: true
        )
        updatePaymentMethodVC.delegate = self

        navigationController?.pushViewController(updatePaymentMethodVC, animated: true)
    }
}

// MARK: - ElementDelegate

extension PayWithLinkViewController.WalletViewController: ElementDelegate {

    func didUpdate(element: Element) {
        switch expiryDateElement.validationState {
        case .valid:
            viewModel.expiryDate = CardExpiryDate(expiryDateElement.text)
        case .invalid:
            viewModel.expiryDate = nil
        }

        switch cvcElement.validationState {
        case .valid:
            viewModel.cvc = cvcElement.text
        case .invalid:
            viewModel.cvc = nil
        }
    }

    func continueToNextField(element: Element) {
    }

}

// MARK: - PayWithLinkWalletViewModelDelegate

extension PayWithLinkViewController.WalletViewController: PayWithLinkWalletViewModelDelegate {

    func viewModelDidChange(_ viewModel: PayWithLinkViewController.WalletViewModel) {
        updateUI(animated: true)
    }

}

// MARK: - LinkPaymentMethodPickerDataSource

extension PayWithLinkViewController.WalletViewController: LinkPaymentMethodPickerDataSource {

    func numberOfPaymentMethods(in picker: LinkPaymentMethodPicker) -> Int {
        return viewModel.paymentMethods.count
    }

    func paymentPicker(_ picker: LinkPaymentMethodPicker, paymentMethodAt index: Int) -> ConsumerPaymentDetails {
        return viewModel.paymentMethods[index]
    }

}

// MARK: - LinkPaymentMethodPickerDelegate

extension PayWithLinkViewController.WalletViewController: LinkPaymentMethodPickerDelegate {

    func paymentMethodPickerDidChange(_ pickerView: LinkPaymentMethodPicker) {
        viewModel.selectedPaymentMethodIndex = pickerView.selectedIndex
        if viewModel.selectedPaymentMethodIsSupported {
            pickerView.setExpanded(false, animated: true)
        }
    }

    func paymentMethodPicker(
        _ pickerView: LinkPaymentMethodPicker,
        showMenuForItemAt index: Int,
        sourceRect: CGRect
    ) {
        let paymentMethod = viewModel.paymentMethods[index]

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceView = pickerView
        alertController.popoverPresentationController?.sourceRect = sourceRect

        if !paymentMethod.isDefault {
            alertController.addAction(UIAlertAction(
                title: STPLocalizedString(
                    "Set as default",
                    "Label for a button or menu item that sets a payment method as default when tapped."
                ),
                style: .default,
                handler: { [self] _ in
                    paymentPicker.showLoader(at: index)
                    viewModel.setDefaultPaymentMethod(at: index) { [weak self] _ in
                        self?.paymentPicker.hideLoader(at: index)
                        self?.paymentPicker.reloadData()
                    }
                }
            ))
        }

        if case ConsumerPaymentDetails.Details.card(_) = paymentMethod.details {
            alertController.addAction(UIAlertAction(
                title: String.Localized.update_card,
                style: .default,
                handler: { _ in
                    self.updatePaymentMethod(at: index)
                }
            ))
        }

        let removeTitle: String = {
            switch paymentMethod.details {
            case .card:
                return String.Localized.remove_card
            case .bankAccount:
                return STPLocalizedString(
                    "Remove linked account",
                    "Title for a button that when tapped removes a linked bank account."
                )
            case .unparsable:
                return ""
            }
        }()
        alertController.addAction(UIAlertAction(
            title: removeTitle,
            style: .destructive,
            handler: { _ in
                self.removePaymentMethod(at: index)
            }
        ))

        alertController.addAction(UIAlertAction(
            title: String.Localized.cancel,
            style: .cancel
        ))

        present(alertController, animated: true)
    }

    func paymentDetailsPickerDidTapOnAddPayment(_ pickerView: LinkPaymentMethodPicker) {
        if context.elementsSession.onlySupportsLinkBank {
            // If this business is bank-only, bypass the new payment method flow and go straight to connections
            confirmButton.update(state: .processing)
            pickerView.setAddPaymentMethodButtonEnabled(false)
            coordinator?.startInstantDebits { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let paymentDetails):
                    self.didUpdate(paymentMethod: paymentDetails, confirmationExtras: nil)
                case .failure(let error):
                    switch error {
                    case InstantDebitsOnlyAuthenticationSessionManager.Error.canceled:
                        break
                    default:
                        self.updateErrorLabel(for: error)
                    }
                }
                self.paymentPicker.setAddPaymentMethodButtonEnabled(true)
                self.updateUI(animated: false)
            }
        } else {
            let newPaymentVC = PayWithLinkViewController.NewPaymentViewController(
                linkAccount: linkAccount,
                context: context,
                isAddingFirstPaymentMethod: false
            )

            navigationController?.pushViewController(newPaymentVC, animated: true)
        }
    }

}

// MARK: - LinkInstantDebitMandateViewDelegate

extension PayWithLinkViewController.WalletViewController: LinkInstantDebitMandateViewDelegate {

    func instantDebitMandateView(_ mandateView: LinkInstantDebitMandateView, didTapOnLinkWithURL url: URL) {
        let safariVC = SFSafariViewController(url: url)
        #if !os(visionOS)
        safariVC.dismissButtonStyle = .close
        #endif
        safariVC.modalPresentationStyle = .overFullScreen
        present(safariVC, animated: true)
    }

}

// MARK: - UpdatePaymentViewControllerDelegate

extension PayWithLinkViewController.WalletViewController: UpdatePaymentViewControllerDelegate {

    func didUpdate(
        paymentMethod: ConsumerPaymentDetails,
        confirmationExtras: LinkConfirmationExtras?
    ) {
        if let index = viewModel.updatePaymentMethod(paymentMethod) {
            self.paymentPicker.selectedIndex = index
            self.paymentPicker.reloadData()
        }

        if let confirmationExtras {
            // The update screen was only opened to collect missing billing details. Now that we have them,
            // let's confirm the intent.
            confirm(confirmationExtras: confirmationExtras)
        }
    }
}
