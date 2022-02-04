//
//  PayWithLinkViewController-WalletViewController.swift
//  StripeiOS
//
//  Created by Ramon Torres on 10/27/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PayWithLinkViewController {

    final class WalletViewController: BaseViewController {
        let linkAccount: PaymentSheetLinkAccount
        let intent: Intent
        let configuration: PaymentSheet.Configuration

        override var coordinator: PayWithLinkCoordinating? {
            didSet {
                footerView.coordinator = coordinator
            }
        }

        private var paymentMethods: [ConsumerPaymentDetails]

        private let paymentPicker = LinkPaymentMethodPicker()

        private lazy var confirmButton: ConfirmButton = {
            let button = ConfirmButton(style: .stripe, callToAction: intent.callToAction) { [weak self] in
                self?.confirm()
            }
            button.applyLinkTheme()
            return button
        }()

        private lazy var footerView: LinkWalletFooterView = {
            let footerView = LinkWalletFooterView()
            footerView.linkAccount = linkAccount
            return footerView
        }()

        init(
            linkAccount: PaymentSheetLinkAccount,
            intent: Intent,
            configuration: PaymentSheet.Configuration,
            paymentMethods: [ConsumerPaymentDetails]
        ) {
            self.linkAccount = linkAccount
            self.intent = intent
            self.configuration = configuration
            self.paymentMethods = paymentMethods
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            setupUI()

            paymentPicker.delegate = self
            paymentPicker.dataSource = self
            paymentPicker.selectedIndex = paymentMethods.firstIndex(where: { $0.isDefault }) ?? 0
        }

        func setupUI() {
            let stackView = UIStackView(arrangedSubviews: [
                paymentPicker,
                confirmButton,
                footerView
            ])

            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: paymentPicker)
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.directionalLayoutMargins = LinkUI.contentMargins

            let scrollView = UIScrollView()
            scrollView.alwaysBounceVertical = true
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

        func confirm() {
            guard let paymentDetails = paymentPicker.selectedPaymentMethod else {
                assertionFailure("`confirm()` called without a selected payment method")
                return
            }

            switch intent {
            case .paymentIntent(let paymentIntent):
                confirmPayment(for: paymentIntent, with: paymentDetails)
            case .setupIntent(_):
                fatalError("Setup intent is not yet supported")
            }
        }

        func confirmPayment(for intent: STPPaymentIntent, with paymentDetails: ConsumerPaymentDetails) {
            confirmButton.update(state: .processing)

            let resultHandler = { (result: PaymentSheetResult) in
                let state: ConfirmButton.Status = {
                    switch result {
                    case .completed:
                        return .succeeded
                    case .canceled:
                        return .enabled
                    case .failed(_):
                        return .disabled // TODO(csabol): Error handling in Link modal
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
    }

}

private extension PayWithLinkViewController.WalletViewController {

    func removePaymentMethod(at index: Int) {
        let alertController = UIAlertController(
            // TODO(ramont): Localize
            title: "Are you sure you want to remove this card?", 
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
                let paymentMethod = self.paymentMethods[index]
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
            intent: self.intent,
            configuration: self.configuration,
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
        confirmButton.update(state: state)
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
            intent: intent,
            configuration: configuration
        )

        navigationController?.pushViewController(newPaymentVC, animated: true)
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
        self.paymentPicker.reloadData()
    }
}
