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

        private lazy var errorLabel: UILabel = {
            return ElementsUI.makeErrorLabel(theme: LinkUI.appearance.asElementsTheme)
        }()

        private let titleLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .title)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = String.Localized.add_a_payment_method
            return label
        }()

        private lazy var confirmButton: ConfirmButton = .makeLinkButton(
            callToAction: context.callToAction,
            // Use a compact button if we are also displaying the Apple Pay button.
            compact: shouldShowApplePayButton
        ) { [weak self] in
            self?.confirm()
        }

        private lazy var cancelButton: Button = {
            let buttonTitle = isAddingFirstPaymentMethod
                ? String.Localized.pay_another_way
                : String.Localized.cancel

            let configuration: Button.Configuration = shouldShowApplePayButton
                ? .linkPlain()
                : .linkSecondary()

            let button = Button(configuration: configuration, title: buttonTitle)
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

        private lazy var buttonContainer: UIStackView = {
            let vStack = UIStackView(arrangedSubviews: [confirmButton])
            vStack.axis = .vertical
            vStack.spacing = LinkUI.contentSpacing

            if shouldShowApplePayButton {
                vStack.addArrangedSubview(separator)
                vStack.addArrangedSubview(applePayButton)
            }

            vStack.addArrangedSubview(cancelButton)
            return vStack
        }()

        private lazy var addPaymentMethodVC: AddPaymentMethodViewController = {
            var configuration = context.configuration
            configuration.linkPaymentMethodsOnly = true
            configuration.appearance = LinkUI.appearance

            return AddPaymentMethodViewController(
                intent: context.intent,
                configuration: configuration,
                delegate: self
            )
        }()

        private let feedbackGenerator = UINotificationFeedbackGenerator()

        private var shouldShowApplePayButton: Bool {
            return (
                isAddingFirstPaymentMethod &&
                context.shouldOfferApplePay &&
                context.configuration.isApplePayEnabled
            )
        }

        init(
            linkAccount: PaymentSheetLinkAccount,
            context: Context,
            isAddingFirstPaymentMethod: Bool
        ) {
            self.linkAccount = linkAccount
            self.isAddingFirstPaymentMethod = isAddingFirstPaymentMethod
            super.init(context: context)
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
                buttonContainer,
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

                buttonContainer.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: LinkUI.contentMargins.leading),
                buttonContainer.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -LinkUI.contentMargins.trailing),
            ])

            didUpdate(addPaymentMethodVC)
        }

        func confirm() {
            updateErrorLabel(for: nil)

            // Dismiss keyboard
            view.endEditing(true)

            if addPaymentMethodVC.selectedPaymentMethodType == .linkInstantDebit {
                didSelectAddBankAccount()
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

        func didSelectAddBankAccount() {
            confirmButton.update(state: .processing)

            coordinator?.startInstantDebits { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    break
                case .failure(let error):
                    switch error {
                    case LinkFinancialConnectionsAuthManager.Error.canceled:
                        self.confirmButton.update(state: .enabled)
                    default:
                        self.updateErrorLabel(for: error)
                        self.confirmButton.update(state: .enabled)
                    }
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
        func applePayButtonTapped(_ sender: PKPaymentButton) {
            coordinator?.confirmWithApplePay()
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
