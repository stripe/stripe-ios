//
//  PayWithLinkViewController-WalletViewController.swift
//  StripeiOS
//
//  Created by Ramon Torres on 10/27/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import PassKit
import SafariServices

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PayWithLinkViewController {

    final class WalletViewController: BaseViewController {
        struct  Constants {
            static let applePayButtonHeight: CGFloat = 48
        }

        let linkAccount: PaymentSheetLinkAccount
        let context: Context

        let viewModel: WalletViewModel

        override var coordinator: PayWithLinkCoordinating? {
            didSet {
                footerView.coordinator = coordinator
            }
        }

        private lazy var paymentPicker: LinkPaymentMethodPicker = {
            let paymentPicker = LinkPaymentMethodPicker()
            paymentPicker.delegate = self
            paymentPicker.dataSource = self
            paymentPicker.selectedIndex = viewModel.selectedPaymentMethodIndex
            return paymentPicker
        }()

        private lazy var instantDebitMandateView = LinkInstantDebitMandateView(delegate: self)

        private lazy var confirmButton: ConfirmButton = {
            let button = ConfirmButton(
                style: .stripe,
                callToAction: viewModel.confirmButtonCallToAction
            ) { [weak self] in
                self?.confirm()
            }

            button.applyLinkTheme(compact: viewModel.shouldUseCompactConfirmButton)
            return button
        }()

        private lazy var cancelButton: Button = {
            // TODO(ramont): Localize
            let button = Button(configuration: viewModel.cancelButtonConfiguration, title: "Pay another way")
            button.addTarget(self, action: #selector(cancelButtonTapped(_:)), for: .touchUpInside)
            return button
        }()

        private lazy var footerView: LinkWalletFooterView = {
            let footerView = LinkWalletFooterView()
            footerView.linkAccount = linkAccount
            return footerView
        }()

        // TODO(ramont): Localize
        private lazy var separator = SeparatorLabel(text: "Or")

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
            let configuration = TextFieldElement.CVCConfiguration() { [weak self] in
                return self?.viewModel.cardBrand ?? .unknown
            }

            return TextFieldElement(configuration: configuration)
        }()

        private lazy var expiryDateElement: TextFieldElement = {
            let configuration = TextFieldElement.ExpiryDateConfiguration()
            return TextFieldElement(configuration: configuration)
        }()

        private lazy var expiredCardNoticeView: LinkNoticeView = {
            let noticeView = LinkNoticeView(type: .error)
            noticeView.text = viewModel.noticeText
            return noticeView
        }()

        private lazy var cardDetailsRecollectionSection: SectionElement = {
            let sectionElement = SectionElement(
                elements: [
                    SectionElement.MultiElementRow([expiryDateElement, cvcElement])
                ]
            )
            sectionElement.delegate = self
            return sectionElement
        }()

        private lazy var paymentPickerContainerView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                paymentPicker,
                instantDebitMandateView,
                expiredCardNoticeView
            ])
            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            return stackView
        }()

        private lazy var containerView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                paymentPickerContainerView,
                cardDetailsRecollectionSection.view,
                confirmButton,
                footerView,
                separator
            ])
            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: paymentPickerContainerView)
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: cardDetailsRecollectionSection.view)
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.directionalLayoutMargins = LinkUI.contentMargins
            return stackView
        }()

        init(
            linkAccount: PaymentSheetLinkAccount,
            context: Context,
            paymentMethods: [ConsumerPaymentDetails]
        ) {
            self.linkAccount = linkAccount
            self.context = context
            self.viewModel = WalletViewModel(linkAccount: linkAccount, context: context, paymentMethods: paymentMethods)
            super.init(nibName: nil, bundle: nil)
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
                containerView.addArrangedSubview(applePayButton)
            }

            containerView.addArrangedSubview(cancelButton)

            let scrollView = LinkKeyboardAvoidingScrollView()
            scrollView.keyboardDismissMode = .interactive
            scrollView.addSubview(containerView)

            view.addAndPinSubview(scrollView)

            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
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

            expiryDateElement.view.setHiddenIfNecessary(!viewModel.shouldRecollectCardExpiryDate)
            cvcElement.view.setHiddenIfNecessary(!viewModel.shouldRecollectCardCVC)

            confirmButton.update(
                state: viewModel.confirmButtonStatus,
                callToAction: viewModel.confirmButtonCallToAction
            )
        }

        func confirm() {
            guard let paymentDetails = viewModel.selectedPaymentMethod else {
                assertionFailure("`confirm()` called without a selected payment method")
                return
            }

            let confirmWithPaymentDetails: (ConsumerPaymentDetails) -> Void = { [self] paymentDetails in
                if viewModel.shouldRecollectCardCVC {
                    if case let .card(card) = paymentDetails.details {
                        card.cvc = viewModel.cvc
                    }
                }

                confirm(for: context.intent, with: paymentDetails)
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

        func confirm(for intent: Intent, with paymentDetails: ConsumerPaymentDetails) {
            view.endEditing(true)

            confirmButton.update(state: .processing)

            let resultHandler = { (result: PaymentSheetResult) in
                let state: ConfirmButton.Status = {
                    switch result {
                    case .completed:
                        return .succeeded
                    case .canceled:
                        return .enabled
                    case .failed(_):
                        return .disabled // PaymentSheet handles this error and dismisses itself
                    }
                }()

                self.confirmButton.update(state: state, animated: true) {
                    self.coordinator?.finish(withResult: result)
                }
            }
            
            coordinator?.confirm(with: linkAccount,
                                 paymentDetails: paymentDetails,
                                 completion: resultHandler)
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
                // TODO(ramont): Localize
                return "Are you sure you want to remove this card?"
            case .bankAccount:
                // TODO(ramont): Localize
                return "Are you sure you want to remove this linked account?"
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
                    case .failure(_):
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
            intent: context.intent,
            configuration: context.configuration,
            paymentMethod: paymentMethod
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
        case .invalid(_):
            viewModel.expiryDate = nil
        }

        switch cvcElement.validationState {
        case .valid:
            viewModel.cvc = cvcElement.text
        case .invalid(_):
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
                title: "Set as default", // TODO(ramont): Localize
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
                title: "Update card", // TODO(porter): Localize
                style: .default,
                handler: { _ in
                    self.updatePaymentMethod(at: index)
                }
            ))
        }

        let removeTitle: String = {
            switch paymentMethod.details {
            case .card:
                return "Remove card" // TODO(ramont): Localize
            case .bankAccount:
                return "Remove linked account" // TODO(ramont): Localize
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
        let newPaymentVC = PayWithLinkViewController.NewPaymentViewController(
            linkAccount: linkAccount,
            context: context
        )

        navigationController?.pushViewController(newPaymentVC, animated: true)
    }

}

// MARK: - LinkInstantDebitMandateViewDelegate

extension PayWithLinkViewController.WalletViewController: LinkInstantDebitMandateViewDelegate {

    func instantDebitMandateView(_ mandateView: LinkInstantDebitMandateView, didTapOnLinkWithURL url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.dismissButtonStyle = .close
        safariVC.modalPresentationStyle = .overFullScreen
        present(safariVC, animated: true)
    }

}

// MARK: - UpdatePaymentViewControllerDelegate

extension PayWithLinkViewController.WalletViewController: UpdatePaymentViewControllerDelegate {
    
    func didUpdate(paymentMethod: ConsumerPaymentDetails) {
        if let index = viewModel.updatePaymentMethod(paymentMethod) {
            self.paymentPicker.selectedIndex = index
            self.paymentPicker.reloadData()
        }
    }

}
