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

        override var coordinator: PayWithLinkCoordinating? {
            didSet {
                footerView.coordinator = coordinator
            }
        }

        private var paymentMethods: [ConsumerPaymentDetails]

        private lazy var paymentPicker: LinkPaymentMethodPicker = {
            let paymentPicker = LinkPaymentMethodPicker()
            paymentPicker.delegate = self
            paymentPicker.dataSource = self
            paymentPicker.selectedIndex = determineInitiallySelectedPaymentMethod()
            return paymentPicker
        }()

        private lazy var instantDebitMandateView = LinkInstantDebitMandateView(delegate: self)

        private var callToAction: ConfirmButton.CallToActionType {
            if context.selectionOnly {
                guard let selectedPaymentMethod = paymentPicker.selectedPaymentMethod?.paymentMethodType else {
                    return .add(paymentMethodType: .link)
                }
                return .add(paymentMethodType: selectedPaymentMethod)
            } else {
                return context.intent.callToAction
            }
        }

        private var shouldShowApplePayButton: Bool {
            return (
                context.shouldOfferApplePay &&
                context.configuration.isApplePayEnabled
            )
        }

        private lazy var confirmButton: ConfirmButton = {
            let button = ConfirmButton(style: .stripe, callToAction: callToAction) { [weak self] in
                self?.confirm()
            }

            button.applyLinkTheme(compact: shouldShowApplePayButton)
            return button
        }()

        private lazy var cancelButton: Button = {
            let buttonConfiguration: Button.Configuration = shouldShowApplePayButton
                ? .linkPlain()
                : .linkSecondary()

            // TODO(ramont): Localize
            let button = Button(configuration: buttonConfiguration, title: "Pay another way")
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

        private lazy var paymentPickerContainerView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                paymentPicker,
                instantDebitMandateView
            ])

            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            return stackView
        }()

        var shouldShowInstantDebitMandate: Bool {
            if case .bankAccount = paymentPicker.selectedPaymentMethod?.details {
                return true
            }

            return false
        }

        init(
            linkAccount: PaymentSheetLinkAccount,
            context: Context,
            paymentMethods: [ConsumerPaymentDetails]
        ) {
            self.linkAccount = linkAccount
            self.context = context
            self.paymentMethods = paymentMethods
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            updateUI(animated: false)
        }

        func determineInitiallySelectedPaymentMethod() -> Int {
            var indexOfLastAddedPaymentMethod: Int? {
                guard let lastAddedID = context.lastAddedPaymentDetails?.stripeID else {
                    return nil
                }

                return paymentMethods.firstIndex(where: { $0.stripeID == lastAddedID })
            }

            var indexOfDefaultPaymentMethod: Int? {
                return paymentMethods.firstIndex(where: { $0.isDefault })
            }

            return indexOfLastAddedPaymentMethod ?? indexOfDefaultPaymentMethod ?? 0
        }

        func setupUI() {
            let stackView = UIStackView(arrangedSubviews: [
                paymentPickerContainerView,
                confirmButton,
                footerView,
                separator
            ])

            if shouldShowApplePayButton {
                stackView.addArrangedSubview(applePayButton)
            }

            stackView.addArrangedSubview(cancelButton)

            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: paymentPickerContainerView)
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.directionalLayoutMargins = LinkUI.contentMargins

            let scrollView = UIScrollView()
            scrollView.addSubview(stackView)

            view.addAndPinSubview(scrollView)

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
        }

        func updateUI(animated: Bool) {
            paymentPickerContainerView.toggleArrangedSubview(
                instantDebitMandateView,
                shouldShow: shouldShowInstantDebitMandate,
                animated: animated
            )
        }

        func confirm() {
            guard let paymentDetails = paymentPicker.selectedPaymentMethod else {
                assertionFailure("`confirm()` called without a selected payment method")
                return
            }
            
            confirm(for: context.intent, with: paymentDetails)
        }

        func confirm(for intent: Intent, with paymentDetails: ConsumerPaymentDetails) {
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
        let paymentMethod = paymentMethods[index]

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
            title: "Remove", // TODO(ramont): Localize
            style: .destructive,
            handler: { _ in
                self.paymentPicker.showLoader(at: index)

                self.linkAccount.deletePaymentDetails(id: paymentMethod.stripeID) { result in
                    switch result {
                    case .success:
                        self.paymentMethods.remove(at: index)
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
        let paymentMethod = self.paymentMethods[index]
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

extension PayWithLinkViewController.WalletViewController: LinkPaymentMethodPickerDataSource {

    func numberOfPaymentMethods(in picker: LinkPaymentMethodPicker) -> Int {
        return paymentMethods.count
    }

    func paymentPicker(_ picker: LinkPaymentMethodPicker, paymentMethodAt index: Int) -> ConsumerPaymentDetails {
        paymentMethods[index]
    }

}

extension PayWithLinkViewController.WalletViewController: LinkPaymentMethodPickerDelegate {

    func paymentMethodPickerDidChange(_ pickerView: LinkPaymentMethodPicker) {
        let state: ConfirmButton.Status = pickerView.selectedPaymentMethod == nil ? .disabled : .enabled
        confirmButton.update(state: state, callToAction: callToAction)
        updateUI(animated: true)
    }

    func paymentMethodPicker(
        _ pickerView: LinkPaymentMethodPicker,
        showMenuForItemAt index: Int,
        sourceRect: CGRect
    ) {
        let paymentMethod = paymentMethods[index]

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceView = pickerView
        alertController.popoverPresentationController?.sourceRect = sourceRect

        if !paymentMethod.isDefault {
            alertController.addAction(UIAlertAction(
                title: "Set as default", // TODO(ramont): Localize
                style: .default,
                handler: { _ in
                    self.paymentPicker.showLoader(at: index)
                    
                    self.linkAccount.updatePaymentDetails(id: paymentMethod.stripeID,
                                                          updateParams: UpdatePaymentDetailsParams(isDefault: true, details: nil)) { result in
                        switch result {
                        case .success(let updatedPaymentDetails):
                            self.paymentMethods.forEach({ $0.isDefault = false })
                            self.paymentMethods[index] = updatedPaymentDetails
                        case .failure(_):
                            break
                        }

                        self.paymentPicker.hideLoader(at: index)
                        self.paymentPicker.reloadData()
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

extension PayWithLinkViewController.WalletViewController: LinkInstantDebitMandateViewDelegate {

    func instantDebitMandateView(_ mandateView: LinkInstantDebitMandateView, didTapOnLinkWithURL url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.dismissButtonStyle = .close
        safariVC.modalPresentationStyle = .overFullScreen
        present(safariVC, animated: true)
    }

}

extension PayWithLinkViewController.WalletViewController: UpdatePaymentViewControllerDelegate {
    
    func didUpdate(paymentMethod: ConsumerPaymentDetails) {
        guard let index = paymentMethods.firstIndex(where: {$0.stripeID == paymentMethod.stripeID}) else {
            return
        }
        
        if paymentMethod.isDefault {
            self.paymentMethods.forEach({ $0.isDefault = false })
        }
        
        self.paymentMethods[index] = paymentMethod
        self.paymentPicker.selectedIndex = index
        self.paymentPicker.reloadData()

        updateUI(animated: true)
    }

}

/// Helper functions for ConsumerPaymentDetails
extension ConsumerPaymentDetails {
    var paymentMethodType: STPPaymentMethodType {
        switch details {
        case .card:
            return .card
        case .bankAccount:
            return .linkInstantDebit
        }
    }
}
