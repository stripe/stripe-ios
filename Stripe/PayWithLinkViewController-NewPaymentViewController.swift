//
//  PayWithLinkViewController-NewPaymentViewController.swift
//  StripeiOS
//
//  Created by Ramon Torres on 11/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PayWithLinkViewController {

    /// For internal SDK use only
    @objc(STP_Internal_NewPaymentViewController)
    final class NewPaymentViewController: BaseViewController {
        let linkAccount: PaymentSheetLinkAccount
        let context: Context
        let isAddingFirstPaymentMethod: Bool

        private lazy var errorLabel: UILabel = {
            return ElementsUI.makeErrorLabel()
        }()

        private let titleLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .title)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = STPLocalizedString(
                "Add a payment method",
                """
                Text for a button that, when tapped, displays another screen where the customer
                can add a new payment method
                """
            )
            return label
        }()

        private lazy var confirmButton: ConfirmButton = .makeLinkButton(
            callToAction: context.selectionOnly
                ? .add(paymentMethodType: addPaymentMethodVC.selectedPaymentMethodType)
                : context.intent.callToAction
        ) { [weak self] in
            self?.confirm()
        }

        private lazy var cancelButton: Button = {
            let buttonTitle = isAddingFirstPaymentMethod
                ? String.Localized.pay_another_way
                : String.Localized.cancel

            let button = Button(configuration: .linkSecondary(), title: buttonTitle)
            button.addTarget(self, action: #selector(cancelButtonTapped(_:)), for: .touchUpInside)
            return button
        }()

        private lazy var addPaymentMethodVC: AddPaymentMethodViewController = {
            var configuration = context.configuration
            configuration.linkPaymentMethodsOnly = true

            return AddPaymentMethodViewController(
                intent: context.intent,
                configuration: configuration,
                delegate: self
            )
        }()

        private var connectionsAuthManager: LinkFinancialConnectionsAuthManager?

        private let feedbackGenerator = UINotificationFeedbackGenerator()

        init(
            linkAccount: PaymentSheetLinkAccount,
            context: Context,
            isAddingFirstPaymentMethod: Bool
        ) {
            self.linkAccount = linkAccount
            self.context = context
            self.isAddingFirstPaymentMethod = isAddingFirstPaymentMethod
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            addChild(addPaymentMethodVC)

            view.backgroundColor = .linkBackground

            addPaymentMethodVC.view.backgroundColor = .clear
            errorLabel.isHidden = true

            let stackView = UIStackView(arrangedSubviews: [
                titleLabel,
                addPaymentMethodVC.view,
                errorLabel,
                confirmButton,
                cancelButton
            ])

            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.alignment = .center
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: titleLabel)
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: addPaymentMethodVC.view)
            stackView.translatesAutoresizingMaskIntoConstraints = false

            let scrollView = LinkKeyboardAvoidingScrollView()
            scrollView.keyboardDismissMode = .interactive
            scrollView.addSubview(stackView)

            contentView.addAndPinSubview(scrollView)

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: preferredContentMargins.top),
                stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -preferredContentMargins.bottom),
                stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

                titleLabel.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: preferredContentMargins.leading),
                titleLabel.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -preferredContentMargins.trailing),

                addPaymentMethodVC.view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                addPaymentMethodVC.view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

                confirmButton.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: preferredContentMargins.leading),
                confirmButton.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -preferredContentMargins.trailing),

                cancelButton.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: LinkUI.contentMargins.leading),
                cancelButton.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -LinkUI.contentMargins.trailing)
            ])

            confirmButton.update(state: .disabled)
        }

        func confirm() {
            updateErrorLabel(for: nil)

            // Dismiss keyboard
            view.endEditing(true)

            if addPaymentMethodVC.selectedPaymentMethodType == .linkInstantDebit {
                didSelectAddBankAccount(addPaymentMethodVC)
                return
            }
            
            guard let newPaymentOption = addPaymentMethodVC.paymentOption,
                  case .new(let confirmParams) = newPaymentOption else {
                assertionFailure()
                return
            }

            feedbackGenerator.prepare()
            confirmButton.update(state: .processing)

            linkAccount.createPaymentDetails(with: confirmParams.paymentMethodParams) { [weak self] result in
                guard let self = self else {
                    return
                }

                switch result {
                case .success(let paymentDetails):
                    if case .card(let card) = paymentDetails.details {
                        card.cvc = confirmParams.paymentMethodParams.card?.cvc
                    }
                    
                    self.coordinator?.confirm(with: self.linkAccount,
                                              paymentDetails: paymentDetails,
                                              completion: { [weak self] result in
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

                        self?.feedbackGenerator.notificationOccurred(.success)
                        self?.confirmButton.update(state: state, animated: true) {
                            if state == .succeeded {
                                self?.coordinator?.finish(withResult: result)
                            }
                        }
                    })
                case .failure(let error):
                    self.feedbackGenerator.notificationOccurred(.error)
                    self.confirmButton.update(state: .enabled, animated: true)
                    self.updateErrorLabel(for: error)
                }
            }
        }

        func didSelectAddBankAccount(_ viewController: AddPaymentMethodViewController) {
            confirmButton.update(state: .processing)

            connectionsAuthManager = LinkFinancialConnectionsAuthManager(
                linkAccount: linkAccount,
                window: view.window
            )

            linkAccount.createLinkAccountSession() { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let linkAccountSession):
                    self.connectionsAuthManager?.start(
                        clientSecret: linkAccountSession.clientSecret
                    ) { [weak self] result in
                        guard let self = self else { return }

                        switch result {
                        case .success(let linkedAccountID):
                            self.linkAccount.createPaymentDetails(
                                linkedAccountId: linkedAccountID
                            ) { result in
                                switch result {
                                case .success(let paymentDetails):
                                    // Store last added payment details so we can automatically select it on wallet
                                    self.context.lastAddedPaymentDetails = paymentDetails
                                    self.coordinator?.accountUpdated(self.linkAccount)
                                    // Do not update confirmButton -- leave in processing while coordinator updates
                                case .failure(let error):
                                    self.updateErrorLabel(for: error)
                                    self.confirmButton.update(state: .enabled)
                                }
                            }
                        case.canceled:
                            self.confirmButton.update(state: .enabled)
                        case .failure(let error):
                            self.updateErrorLabel(for: error)
                            self.confirmButton.update(state: .enabled)
                        }
                    }
                case .failure(let error):
                    self.updateErrorLabel(for: error)
                }
            }
        }
        
        func updateErrorLabel(for error: Error?) {
            errorLabel.text = error?.nonGenericDescription
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                self.errorLabel.setHiddenIfNecessary(error == nil)
            }
        }

        @objc
        func cancelButtonTapped(_ sender: Button) {
            if isAddingFirstPaymentMethod {
                coordinator?.cancel()
            } else {
                navigationController?.popViewController(animated: true)
            }
        }

    }

}

extension PayWithLinkViewController.NewPaymentViewController: AddPaymentMethodViewControllerDelegate {

    func didUpdate(_ viewController: AddPaymentMethodViewController) {
        if viewController.selectedPaymentMethodType == .linkInstantDebit {
            confirmButton.update(state: .enabled, style: .stripe, callToAction: .add(paymentMethodType: .linkInstantDebit))
        } else {
            confirmButton.update(state: viewController.paymentOption != nil ? .enabled : .disabled, callToAction: context.selectionOnly ? .add(paymentMethodType: viewController.selectedPaymentMethodType) : context.intent.callToAction)
        }
        updateErrorLabel(for: nil)
    }

    func shouldOfferLinkSignup(_ viewController: AddPaymentMethodViewController) -> Bool {
        return false
    }

}
