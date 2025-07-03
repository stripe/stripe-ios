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
            paymentPicker.billingDetails = context.configuration.defaultBillingDetails
            paymentPicker.billingDetailsCollectionConfiguration = context.configuration.billingDetailsCollectionConfiguration
            return paymentPicker
        }()

        private lazy var mandateView = LinkMandateView(delegate: self)

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

        private lazy var cancelButton: Button? = {
            guard let cancelButtonConfiguration = viewModel.cancelButtonConfiguration else {
                return nil
            }
            let button = Button(
                configuration: cancelButtonConfiguration,
                title: viewModel.context.secondaryButtonLabel
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
                mandateView,
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
            paymentMethods: [ConsumerPaymentDetails],
            shippingAddresses: [ShippingAddressesResponse.ShippingAddress]
        ) {
            self.linkAccount = linkAccount
            self.viewModel = WalletViewModel(linkAccount: linkAccount, context: context, paymentMethods: paymentMethods, shippingAddresses: shippingAddresses)
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

            if let cancelButton {
                containerView.addArrangedSubview(cancelButton)
            }

            contentView.addAndPinSubview(containerView)

            // If the initially selected payment method is not supported, we should automatically
            // expand the payment picker to hint the user to pick another payment method.
            if !viewModel.selectedPaymentMethodIsSupported {
                paymentPicker.setPaymentListExpanded(true, animated: false)
            }

            if context.initiallySelectedPaymentDetailsID != nil {
                // Automatically expand, since the user is likely here to change the payment method
                paymentPicker.setPaymentListExpanded(true, animated: false)
            }
        }

        func updateUI(animated: Bool) {
            if !viewModel.shouldRecollectCardCVC && !viewModel.shouldRecollectCardExpiryDate {
                cardDetailsRecollectionSection.view.endEditing(true)
            }

            if let mandate = viewModel.mandate {
                mandateView.setText(mandate)
            }

            paymentPicker.reloadPaymentMethods()
            paymentPickerContainerView.toggleArrangedSubview(
                mandateView,
                shouldShow: viewModel.shouldShowMandate,
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

        func reloadPaymentDetails(completion: (() -> Void)?) {
            let supportedPaymentDetailsTypes = linkAccount
                .supportedPaymentDetailsTypes(for: context.elementsSession)
                .toSortedArray()

            // Fire and forget; ignore any errors that might happen here.
            linkAccount.listPaymentDetails(supportedTypes: supportedPaymentDetailsTypes) { [weak self] result in
                if case .success(let paymentDetails) = result {
                    self?.viewModel.updatePaymentMethods(paymentDetails)
                }
                completion?()
            }
        }

        func confirm(confirmationExtras: LinkConfirmationExtras = LinkConfirmationExtras()) {
            guard let paymentDetails = viewModel.selectedPaymentMethod else {
                stpAssertionFailure("`confirm()` called without a selected payment method")
                return
            }

            let confirmWithPaymentDetails: (ConsumerPaymentDetails) -> Void = { [self] paymentDetails in
                if viewModel.shouldRecollectCardCVC {
                    if case let .card(card) = paymentDetails.details {
                        card.cvc = viewModel.cvc
                    }
                }

                if isMissingRequestedBillingDetails(paymentDetails) {
                    handleIncompleteBillingDetails(for: paymentDetails, with: confirmationExtras)
                } else if context.launchedFromFlowController, let paymentMethod = viewModel.selectedPaymentMethod {
                    coordinator?.handlePaymentDetailsSelected(paymentMethod, shippingAddress: viewModel.selectedShippingAddress, confirmationExtras: confirmationExtras)
                } else {
                    confirm(for: context.intent, with: paymentDetails, confirmationExtras: confirmationExtras)
                }
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

        /// Returns whether the provided `paymentDetails` is missing any of the required billing details.
        private func isMissingRequestedBillingDetails(_ paymentDetails: ConsumerPaymentDetails) -> Bool {
            let paymentDetailsAreSupported = paymentDetails.supports(
                billingDetailsCollectionConfiguration,
                in: linkAccount.currentSession
            )

            return !paymentDetailsAreSupported
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
            coordinator?.allowSheetDismissal(false)
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
                        self?.coordinator?.allowSheetDismissal(true)
                        self?.coordinator?.finish(withResult: result, deferredIntentConfirmationType: deferredIntentConfirmationType)
                    }
                case .canceled:
                    self?.confirmButton.update(state: .enabled)
                    self?.coordinator?.allowSheetDismissal(true)
                case .failed(let error):
                    #if !os(visionOS)
                    self?.feedbackGenerator.notificationOccurred(.error)
                    #endif
                    self?.updateErrorLabel(for: error)
                    self?.confirmButton.update(state: .enabled)
                    self?.coordinator?.allowSheetDismissal(true)
                }
            }
        }

        @objc
        func applePayButtonTapped(_ sender: PKPaymentButton) {
            coordinator?.confirmWithApplePay()
        }

        @objc
        func cancelButtonTapped(_ sender: Button) {
            coordinator?.cancel(shouldReturnToPaymentSheet: true)
        }

    }

}

extension PayWithLinkViewController.WalletViewController {
    struct Action {
        let title: String
        let style: UIAlertAction.Style
        let action: () -> Void

        var contextMenuAttribute: UIMenuElement.Attributes {
            switch style {
            case .default, .cancel: return []
            case .destructive: return [.destructive]
            @unknown default: return []
            }
        }

        init(
            title: String,
            style: UIAlertAction.Style = .default,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.style = style
            self.action = action
        }
    }

    func actions(for index: Int, includeCancelAction: Bool) -> [Action] {
        let paymentMethod = viewModel.paymentMethods[index]
        var actions: [Action] = []

        if !paymentMethod.isDefault {
            let setAsDefaultAction = Action(
                title: STPLocalizedString(
                    "Set as default",
                    "Label for a button or menu item that sets a payment method as default when tapped."
                ),
                action: { [weak self] in
                    self?.paymentPicker.showLoaderForPaymentMethod(at: index)
                    self?.viewModel.setDefaultPaymentMethod(at: index) { [weak self] _ in
                        self?.paymentPicker.hideLoaderForPaymentMethod(at: index)
                        self?.paymentPicker.reloadPaymentMethods()
                    }
                }
            )
            actions.append(setAsDefaultAction)
        }

        if case ConsumerPaymentDetails.Details.card(_) = paymentMethod.details {
            let updateCardAction = Action(
                title: String.Localized.update_card,
                action: { [weak self] in
                    self?.updatePaymentMethod(at: index)
                }
            )
            actions.append(updateCardAction)
        }

        let removeTitle: String? = {
            switch paymentMethod.details {
            case .card:
                return String.Localized.remove_card
            case .bankAccount:
                return STPLocalizedString(
                    "Remove linked account",
                    "Title for a button that when tapped removes a linked bank account."
                )
            case .unparsable:
                return nil
            }
        }()

        if let removeTitle {
            let removeAction = Action(
                title: removeTitle,
                style: .destructive,
                action: { [weak self] in
                    self?.removePaymentMethod(at: index)
                }
            )
            actions.append(removeAction)
        }

        if includeCancelAction {
            let cancelAction = Action(
                title: String.Localized.cancel,
                style: .cancel,
                action: {}
            )
            actions.append(cancelAction)
        }

        return actions
    }
}

private extension PayWithLinkViewController.WalletViewController {

    func removeShippingAddress(at index: Int) {

        let alertTitle: String = {
            return STPLocalizedString(
                "Are you sure you want to remove this address?",
                "Title of confirmation prompt when removing a shipping address."
            )
        }()

        let alertController = UIAlertController(
            title: alertTitle,
            message: STPLocalizedString(
                "This address will be removed from your Link account.",
                "Description of confirmation prompt when removing a shipping address."
            ),
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
                self.paymentPicker.showLoaderForShippingAddress(at: index)

                self.viewModel.deleteAddress(at: index) { result in
                    switch result {
                    case .success:
                        self.paymentPicker.removeShippingAddress(at: index, animated: true)
                    case .failure:
                        break
                    }

                    self.paymentPicker.hideLoaderForShippingAddress(at: index)
                }
            }
        ))

        present(alertController, animated: true)
    }

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
                self.paymentPicker.showLoaderForPaymentMethod(at: index)

                self.viewModel.deletePaymentMethod(at: index) { result in
                    switch result {
                    case .success:
                        self.paymentPicker.removePaymentMethod(at: index, animated: true)
                    case .failure:
                        break
                    }

                    self.paymentPicker.hideLoaderForPaymentMethod(at: index)
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

        bottomSheetController?.pushContentViewController(updatePaymentMethodVC)
    }

    func collectRemainingBillingDetailsAndConfirm(for paymentMethod: ConsumerPaymentDetails) {
        let updatePaymentMethodVC = PayWithLinkViewController.UpdatePaymentViewController(
            linkAccount: linkAccount,
            context: context,
            paymentMethod: paymentMethod,
            isBillingDetailsUpdateFlow: true
        )
        updatePaymentMethodVC.delegate = self

        bottomSheetController?.pushContentViewController(updatePaymentMethodVC)
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
    var accountEmail: String {
        linkAccount.email
    }
}

extension PayWithLinkViewController.WalletViewController: LinkPaymentMethodListDataSource {
    var selectedIndex: Int {
        viewModel.selectedPaymentMethodIndex
    }

    func numberOfPaymentMethods() -> Int {
        return viewModel.paymentMethods.count
    }

    func paymentPicker(paymentMethodAt index: Int) -> ConsumerPaymentDetails {
        return viewModel.paymentMethods[index]
    }

    func isPaymentMethodSupported(_ paymentMethod: ConsumerPaymentDetails?) -> Bool {
        viewModel.isPaymentMethodSupported(paymentMethod: paymentMethod)
    }
}

extension PayWithLinkViewController.WalletViewController: LinkShippingAddressListDatasource {
    func numberOfShippingAddresses() -> Int {
        viewModel.shippingAddresses.count
    }

    func shippingAddress(atIndex index: Int) -> ShippingAddressesResponse.ShippingAddress {
        viewModel.shippingAddresses[index]
    }

    var selectedShippingAddressIndex: Int {
        viewModel.selectedShippingAddressIndex
    }
}

// MARK: - LinkPaymentMethodPickerDelegate

extension PayWithLinkViewController.WalletViewController: AddressViewControllerDelegate {
    func addressViewControllerDidFinish(_ addressViewController: AddressViewController, with address: AddressViewController.AddressDetails?) {
        addressViewController.dismiss(animated: true)
        if let address {
            paymentPicker.setAddShippingAddressButtonIsLoading(true)
            viewModel.createShippingAddress(address: .init(administrativeArea: address.address.state, countryCode: address.address.country, dependentLocality: nil, line1: address.address.line1, line2: address.address.line2, locality: address.address.city, name: address.name, postalCode: address.address.postalCode, sortingCode: nil)) { [weak self] _ in
                self?.paymentPicker.reloadShippingAddresses()
                self?.paymentPicker.setAddShippingAddressButtonIsLoading(false)
            }
            print(address)
        }
    }
}

extension PayWithLinkViewController.WalletViewController: LinkShippingAddressListDelegate {
    func shippingAddressListDidExpand() {
        paymentPicker.setPaymentListExpanded(false, animated: true)
    }
    
    func didTapOnAddShippingAddress(
        sourceRect: CGRect
    ) {
        self.bottomSheetController?.present(UINavigationController(rootViewController: AddressViewController(configuration: .init(appearance: LinkUI.appearance), delegate: self)), animated: true)
    }

    func didSelectShippingAddress(atIndex index: Int) {
        viewModel.selectedShippingAddressIndex = index
        paymentPicker.setShippingAddressExpanded(false, animated: true)
        paymentPicker.reloadShippingAddresses()
    }

    func showMenuForShippingAddress(
        atIndex index: Int,
        sourceRect: CGRect
    ) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceView = paymentPicker
        alertController.popoverPresentationController?.sourceRect = sourceRect

        let actions = shippingAddressActions(for: index, includeCancelAction: true)
        for action in actions {
            alertController.addAction(
                UIAlertAction(
                    title: action.title,
                    style: action.style,
                    handler: { _ in action.action() }
                )
            )
        }

        present(alertController, animated: true)
    }

    func shippingAddressActions(for index: Int, includeCancelAction: Bool) -> [Action] {
        let shippingAddress = viewModel.shippingAddresses[index]
        var actions: [Action] = []

        if shippingAddress.isDefault != true {
            let setAsDefaultAction = Action(
                title: STPLocalizedString(
                    "Set as default",
                    "Label for a button or menu item that sets a payment method as default when tapped."
                ),
                action: { [weak self] in
                    self?.paymentPicker.showLoaderForShippingAddress(at: index)
                    self?.viewModel.setDefaultShippingAddress(at: index) { [weak self] _ in
                        self?.paymentPicker.hideLoaderForShippingAddress(at: index)
                        self?.paymentPicker.reloadShippingAddresses()
                    }
                }
            )
            actions.append(setAsDefaultAction)
        }

        let removeTitle: String = STPLocalizedString(
            "Remove address",
            "Title for a button that when tapped removes a shipping address."
        )

            let removeAction = Action(
                title: removeTitle,
                style: .destructive,
                action: { [weak self] in
                    self?.removeShippingAddress(at: index)
                }
            )
            actions.append(removeAction)

        if includeCancelAction {
            let cancelAction = Action(
                title: String.Localized.cancel,
                style: .cancel,
                action: {}
            )
            actions.append(cancelAction)
        }

        return actions
    }

    func menuActionForShippingAddress(
        atIndex index: Int
    ) -> [PayWithLinkViewController.WalletViewController.Action] {
        shippingAddressActions(for: index, includeCancelAction: false)
    }
}

extension PayWithLinkViewController.WalletViewController: LinkPaymentMethodPickerDelegate, LinkPaymentMethodListDelegate {

    func paymentListDidExpand() {
        paymentPicker.setShippingAddressExpanded(false, animated: true)
    }

    func paymentMethodPicker(didSelectIndex index: Int) {
        viewModel.selectedPaymentMethodIndex = index
        if viewModel.selectedPaymentMethodIsSupported {
            paymentPicker.setPaymentListExpanded(false, animated: true)
        }
        paymentPicker.reloadPaymentMethods()
    }

    func paymentMethodPicker(
        showMenuForItemAt index: Int,
        sourceRect: CGRect
    ) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceView = paymentPicker
        alertController.popoverPresentationController?.sourceRect = sourceRect

        let actions = actions(for: index, includeCancelAction: true)
        for action in actions {
            alertController.addAction(
                UIAlertAction(
                    title: action.title,
                    style: action.style,
                    handler: { _ in action.action() }
                )
            )
        }

        present(alertController, animated: true)
    }

    func paymentDetailsPickerDidTapOnAddShippingAddress(sourceRect: CGRect) {
        // TODO: 
    }

    func paymentDetailsPickerDidTapOnAddPayment(
        sourceRect: CGRect
    ) {
        let supportedPaymentDetailsTypes = linkAccount.supportedPaymentDetailsTypes(for: context.elementsSession)

        let bankAndCard = [ConsumerPaymentDetails.DetailsType.bankAccount, .card]
        if bankAndCard.allSatisfy(supportedPaymentDetailsTypes.contains) {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.popoverPresentationController?.sourceView = paymentPicker
            alertController.popoverPresentationController?.sourceRect = sourceRect

            let addBankAction = UIAlertAction(
                title: STPLocalizedString(
                    "Bank",
                    "Label shown in the payment type picker describing a bank payment"
                ),
                style: .default
            ) { [weak self] _ in
                self?.addBankAccount()
            }
            alertController.addAction(addBankAction)

            let addCardAction = UIAlertAction(
                title: STPLocalizedString(
                    "Debit or credit card",
                    "Label shown in the payment type picker describing a card payment"
                ),
                style: .default
            ) { [weak self] _ in
                self?.addCard()
            }
            alertController.addAction(addCardAction)

            let cancelAction = UIAlertAction(title: String.Localized.cancel, style: .cancel)
            alertController.addAction(cancelAction)

            present(alertController, animated: true)
        } else if supportedPaymentDetailsTypes.contains(.bankAccount) {
            addBankAccount()
        } else {
            addCard()
        }
    }

    private func addBankAccount() {
        confirmButton.update(state: .disabled)
        paymentPicker.setAddButtonIsLoading(true)
        coordinator?.startFinancialConnections { [weak self] result in
            let completion = {
                self?.confirmButton.update(state: .enabled)
                self?.paymentPicker.setAddButtonIsLoading(false)
            }

            guard case .completed = result else {
                completion()
                return
            }

            self?.reloadPaymentDetails(completion: completion)
        }
    }

    private func addCard() {
        let newPaymentVC = PayWithLinkViewController.NewPaymentViewController(
            linkAccount: linkAccount,
            context: context,
            isAddingFirstPaymentMethod: false
        )

        bottomSheetController?.pushContentViewController(newPaymentVC)
    }

    func paymentMethodPicker(menuActionsForItemAt index: Int) -> [Action] {
        actions(for: index, includeCancelAction: false)
    }

    func didTapOnAccountMenuItem(_ picker: LinkPaymentMethodPicker, sourceRect: CGRect) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.popoverPresentationController?.sourceView = paymentPicker
        actionSheet.popoverPresentationController?.sourceRect = sourceRect

        actionSheet.addAction(UIAlertAction(
            title: STPLocalizedString("Log out of Link", "Title of the logout action."),
            style: .destructive,
            handler: { [weak self] _ in
                self?.coordinator?.logout(cancel: true)
            }
        ))
        actionSheet.addAction(UIAlertAction(title: String.Localized.cancel, style: .cancel))

        present(actionSheet, animated: true)
    }
}

// MARK: - LinkInstantDebitMandateViewDelegate

extension PayWithLinkViewController.WalletViewController: LinkMandateViewDelegate {

    func mandateView(_ mandateView: LinkMandateView, didTapOnLinkWithURL url: URL) {
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
        viewModel.updatePaymentMethod(paymentMethod)
        self.paymentPicker.reloadPaymentMethods()

        if let confirmationExtras {
            // The update screen was only opened to collect missing billing details. Now that we have them,
            // let's confirm the intent.
            confirm(confirmationExtras: confirmationExtras)
        }
    }
}
