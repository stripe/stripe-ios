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

        var accountEmail: String {
            linkAccount.email
        }

        private lazy var theme: ElementsAppearance = {
            var theme = LinkUI.appearance.asElementsTheme

            if let primaryColor = viewModel.linkAppearance?.colors?.primary {
                theme.colors.primary = primaryColor
            }

            return theme
        }()

        private lazy var paymentPicker: LinkPaymentMethodPicker = {
            let paymentPicker = LinkPaymentMethodPicker(linkConfiguration: context.linkConfiguration)
            paymentPicker.delegate = self
            paymentPicker.dataSource = self
            paymentPicker.supportedPaymentMethodTypes = viewModel.supportedPaymentMethodTypes
            paymentPicker.billingDetails = context.configuration.defaultBillingDetails
            paymentPicker.billingDetailsCollectionConfiguration = context.configuration.billingDetailsCollectionConfiguration
            paymentPicker.linkAppearance = viewModel.linkAppearance
            return paymentPicker
        }()

        private lazy var mandateView = LinkMandateView(delegate: self, linkAppearance: viewModel.linkAppearance)

        private lazy var confirmButton = ConfirmButton.makeLinkButton(
            callToAction: viewModel.confirmButtonCallToAction,
            showProcessingLabel: context.showProcessingLabel,
            compact: viewModel.shouldUseCompactConfirmButton,
            linkAppearance: viewModel.linkAppearance,
            didTapWhenDisabled: { [weak self] in
                self?.cardDetailsRecollectionSection.showAllValidationErrors()
            }
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

            return TextFieldElement(configuration: configuration, theme: theme)
        }()

        private lazy var expiryDateElement: TextFieldElement = {
            let configuration = TextFieldElement.ExpiryDateConfiguration()
            return TextFieldElement(configuration: configuration, theme: theme)
        }()

        private lazy var debitCardHintView: LinkHintMessageView? = {
            guard let hintMessage = viewModel.debitCardHintIfSupported(for: linkAccount) else {
                return nil
            }
            return LinkHintMessageView(message: hintMessage, style: .filled)
        }()

        private lazy var cardDetailsRecollectionRow = SectionElement.MultiElementRow([expiryDateElement, cvcElement], theme: theme)

        private lazy var cardDetailsRecollectionSection: SectionElement = {
            let sectionElement = SectionElement(elements: [cardDetailsRecollectionRow], theme: theme)
            sectionElement.delegate = self
            return sectionElement
        }()

        private lazy var paymentPickerContainerView: UIStackView = {
            var arrangedSubviews: [UIView] = [paymentPicker]

            if let debitCardHintView = debitCardHintView {
                arrangedSubviews.append(debitCardHintView)
            }

            let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            return stackView
        }()

        private lazy var errorView: LinkHintMessageView = {
            let view = LinkHintMessageView(message: nil, style: .error)
            view.isHidden = true
            return view
        }()

        private lazy var containerView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                paymentPickerContainerView,
                cardDetailsRecollectionSection.view,
                errorView,
                mandateView,
                confirmButton,
            ])
            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.directionalLayoutMargins = preferredContentMargins
            return stackView
        }()

        private var bottomInset: CGFloat {
            if #available(iOS 26.0, *) {
                0
            } else {
                LinkUI.bottomInset
            }
        }

        private var containerViewBottomConstraint: NSLayoutConstraint!

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

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            registerForKeyboardNotifications()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            NotificationCenter.default.removeObserver(self)
        }

        func setupUI() {
            if viewModel.shouldShowApplePayButton {
                containerView.addArrangedSubview(separator)
                containerView.addArrangedSubview(applePayButton)
            }

            if let cancelButton {
                containerView.addArrangedSubview(cancelButton)
            }

            contentView.addSubview(containerView)
            containerView.translatesAutoresizingMaskIntoConstraints = false

            containerViewBottomConstraint = containerView.bottomAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.bottomAnchor,
                constant: -bottomInset
            )

            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
                containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                containerViewBottomConstraint,
            ])

            // If the initially selected payment method is not supported, we should automatically
            // expand the payment picker to hint the user to pick another payment method.
            if !viewModel.selectedPaymentMethodIsSupported {
                paymentPicker.setExpanded(true, animated: false)
            }

            if context.initiallySelectedPaymentDetailsID != nil {
                // Automatically expand, since the user is likely here to change the payment method
                paymentPicker.setExpanded(true, animated: false)
            }
        }

        func updateUI(animated: Bool) {
            if !viewModel.shouldRecollectCardCVC && !viewModel.shouldRecollectCardExpiryDate {
                cardDetailsRecollectionSection.view.endEditing(true)
            }

            if let mandate = viewModel.mandate {
                mandateView.setText(mandate)
            }

            paymentPicker.reloadData()
            paymentPickerContainerView.toggleArrangedSubview(
                mandateView,
                shouldShow: viewModel.shouldShowMandate,
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
                cardDetailsRecollectionRow.updateDividerVisibility()
                cardDetailsRecollectionSection.view.layoutIfNeeded()
            }

            confirmButton.update(
                state: viewModel.confirmButtonStatus,
                callToAction: viewModel.confirmButtonCallToAction
            )
        }

        func updateErrorLabel(for error: Error?) {
            errorView.text = error?.nonGenericDescription
            containerView.toggleArrangedSubview(errorView, shouldShow: error != nil, animated: true)
        }

        func reloadPaymentDetails(completion: (() -> Void)?) {
            let supportedPaymentDetailsTypes = context
                .getSupportedPaymentDetailsTypes(linkAccount: linkAccount)
                .toSortedArray()

            // Fire and forget; ignore any errors that might happen here.
            linkAccount.listPaymentDetails(
                supportedTypes: supportedPaymentDetailsTypes,
                shouldRetryOnAuthError: true
            ) { [weak self] result in
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

                Task {
                    let billingDetailsValidator = LinkBillingDetailsValidator(linkAccount: linkAccount, context: context)
                    let validationResult = await billingDetailsValidator.validate(paymentDetails)

                    switch validationResult {
                    case .complete(let updatedPaymentDetails, let confirmationExtras):
                        viewModel.updatePaymentMethod(updatedPaymentDetails)
                        if context.launchedFromFlowController {
                            coordinator?.handlePaymentDetailsSelected(updatedPaymentDetails, confirmationExtras: confirmationExtras)
                        } else {
                            confirm(for: context.intent, with: updatedPaymentDetails, confirmationExtras: confirmationExtras)
                        }
                    case .incomplete(let partialPaymentDetails):
                        collectRemainingBillingDetailsAndConfirm(for: partialPaymentDetails)
                    }
                }
            }

            if viewModel.shouldRecollectCardExpiryDate {
                confirmButton.update(state: .processing)

                viewModel.updateExpiryDate { [weak self] result in
                    switch result {
                    case .success(let paymentDetails):
                        confirmWithPaymentDetails(paymentDetails)
                    case .failure(let error):
                        self?.updateErrorLabel(for: error)
                        self?.confirmButton.update(state: .enabled)
                    }
                }
            } else {
                confirmWithPaymentDetails(paymentDetails)
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
                    self?.paymentPicker.showLoader(at: index)
                    self?.viewModel.setDefaultPaymentMethod(at: index) { [weak self] _ in
                        self?.paymentPicker.hideLoader(at: index)
                        self?.paymentPicker.reloadData()
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
            isBillingDetailsUpdateFlow: false,
            linkAppearance: viewModel.linkAppearance
        )
        updatePaymentMethodVC.delegate = self

        bottomSheetController?.pushContentViewController(updatePaymentMethodVC)
    }

    func collectRemainingBillingDetailsAndConfirm(for paymentMethod: ConsumerPaymentDetails) {
        let updatePaymentMethodVC = PayWithLinkViewController.UpdatePaymentViewController(
            linkAccount: linkAccount,
            context: context,
            paymentMethod: paymentMethod,
            isBillingDetailsUpdateFlow: true,
            linkAppearance: viewModel.linkAppearance
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
    var selectedIndex: Int {
        viewModel.selectedPaymentMethodIndex
    }

    func numberOfPaymentMethods(in picker: LinkPaymentMethodPicker) -> Int {
        return viewModel.paymentMethods.count
    }

    func paymentPicker(_ picker: LinkPaymentMethodPicker, paymentMethodAt index: Int) -> ConsumerPaymentDetails {
        return viewModel.paymentMethods[index]
    }

    func isPaymentMethodSupported(_ paymentMethod: ConsumerPaymentDetails?) -> Bool {
        viewModel.isPaymentMethodSupported(paymentMethod: paymentMethod)
    }
}

// MARK: - LinkPaymentMethodPickerDelegate

extension PayWithLinkViewController.WalletViewController: LinkPaymentMethodPickerDelegate {

    func paymentMethodPicker(_ pickerView: LinkPaymentMethodPicker, didSelectIndex index: Int) {
        viewModel.selectedPaymentMethodIndex = index
        if viewModel.selectedPaymentMethodIsSupported {
            pickerView.setExpanded(false, animated: true)
        }
        pickerView.reloadData()
    }

    func paymentMethodPicker(
        _ pickerView: LinkPaymentMethodPicker,
        showMenuForItemAt index: Int,
        sourceRect: CGRect
    ) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceView = pickerView
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

    func paymentDetailsPickerDidTapOnAddPayment(
        _ pickerView: LinkPaymentMethodPicker,
        sourceRect: CGRect
    ) {
        let supportedPaymentDetailsTypes = context.getSupportedPaymentDetailsTypes(linkAccount: linkAccount)

        let bankAndCard = [ConsumerPaymentDetails.DetailsType.bankAccount, .card]
        if bankAndCard.allSatisfy(supportedPaymentDetailsTypes.contains) {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.popoverPresentationController?.sourceView = pickerView
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

    func paymentMethodPicker(_ picker: LinkPaymentMethodPicker, menuActionsForItemAt index: Int) -> [Action] {
        actions(for: index, includeCancelAction: false)
    }

    func didTapOnAccountMenuItem(
        _ picker: LinkPaymentMethodPicker,
        sourceRect: CGRect
    ) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.popoverPresentationController?.sourceView = picker
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

// MARK: - Keyboard handling

private extension PayWithLinkViewController.WalletViewController {
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardScreenEndFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        let keyboardInViewHeight = view.safeAreaLayoutGuide.layoutFrame.intersection(keyboardViewEndFrame).height

        if notification.name == UIResponder.keyboardWillHideNotification {
            containerViewBottomConstraint.constant = -bottomInset
        } else {
            containerViewBottomConstraint.constant = -keyboardInViewHeight - LinkUI.contentSpacing
        }

        view.setNeedsLayout()
        UIView.animateAlongsideKeyboard(notification) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UpdatePaymentViewControllerDelegate

extension PayWithLinkViewController.WalletViewController: UpdatePaymentViewControllerDelegate {

    func didUpdate(
        paymentMethod: ConsumerPaymentDetails,
        confirmationExtras: LinkConfirmationExtras?
    ) {
        viewModel.updatePaymentMethod(paymentMethod)
        self.paymentPicker.reloadData()

        if let confirmationExtras {
            // The update screen was only opened to collect missing billing details. Now that we have them,
            // let's confirm the intent.
            confirm(confirmationExtras: confirmationExtras)
        }
    }
}
