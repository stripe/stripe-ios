//
//  AddPaymentMethodViewModel.swift
//  StripePaymentSheet
//
//  Created by Eduardo Urias on 8/23/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeFinancialConnections
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

class AddPaymentMethodViewModel: ObservableViewModel {
    let notifier = ViewModelObservationNotifier()

    let intent: Intent
    let configuration: PaymentSheet.Configuration
    let isLinkEnabled: Bool

    let paymentMethodTypeSelectorViewModel: PaymentMethodTypeSelectorViewModel
    private var usBankAccountFormElement: USBankAccountPaymentMethodElement?
    private(set) var paymentMethodFormElement: PaymentMethodElement {
        didSet {
            notifier.notify()
        }
    }

    private(set) var linkAccount: PaymentSheetLinkAccount? = LinkAccountContext.shared.account {
        didSet {
            if oldValue?.sessionState != linkAccount?.sessionState {
                // TODO(link): This code ends up reloading the payment method form when `FlowController.update`
                // is called, losing previous customer input.
                // I added this check to avoid reloading unless necessary but I'm not sure it works.
                // When Link is re-enabled, we should make sure this works!
                paymentMethodFormElement = makeElement(for: paymentMethodTypeSelectorViewModel.selected)
            }
        }
    }

    private(set) var error: Error? {
        didSet {
            notifier.notify()
        }
    }

    var paymentOption: PaymentOption? {
        if let linkEnabledElement = paymentMethodFormElement as? LinkEnabledPaymentMethodElement {
            return linkEnabledElement.makePaymentOption()
        }

        let params = IntentConfirmParams(type: paymentMethodTypeSelectorViewModel.selected)
        params.setDefaultBillingDetailsIfNecessary(for: configuration)
        if let params = paymentMethodFormElement.updateParams(params: params) {
            // TODO(yuki): Hack to support external_paypal
            if paymentMethodTypeSelectorViewModel.selected == .externalPayPal {
                return .externalPayPal(confirmParams: params)
            }
            return .new(confirmParams: params)
        }
        return nil
    }

    weak var presentingViewControllerDelegate: PresentingViewControllerDelegate?

    var overrideBuyButtonBehavior: OverrideableBuyButtonBehavior? {
        if paymentMethodTypeSelectorViewModel.selected == .USBankAccount {
            if let paymentOption = paymentOption,
               case .new = paymentOption
            {
                return nil  // already have PaymentOption
            } else {
                return .LinkUSBankAccount
            }
        }
        return nil
    }

    var overrideCallToAction: ConfirmButton.CallToActionType? {
        return overrideBuyButtonBehavior != nil
        ? ConfirmButton.CallToActionType.customWithLock(title: String.Localized.continue)
        : nil
    }

    var overrideCallToActionShouldEnable: Bool {
        guard let overrideBuyButtonBehavior = overrideBuyButtonBehavior else {
            return false
        }
        switch overrideBuyButtonBehavior {
        case .LinkUSBankAccount:
            return usBankAccountFormElement?.canLinkAccount ?? false
        }
    }

    var bottomNoticeAttributedString: NSAttributedString? {
        if paymentMethodTypeSelectorViewModel.selected == .USBankAccount,
           let usBankPaymentMethodElement = paymentMethodFormElement as? USBankAccountPaymentMethodElement
        {
            return usBankPaymentMethodElement.mandateString
        }
        return nil
    }

    var shouldOfferLinkSignup: Bool { isLinkEnabled && !(linkAccount?.isRegistered ?? false) }

    init(
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        previousCustomerInput: IntentConfirmParams? = nil,
        isLinkEnabled: Bool = false
    ) {
        self.intent = intent
        self.configuration = configuration
        self.isLinkEnabled = isLinkEnabled
        let paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            configuration: configuration,
            logAvailability: true
        )

        assert(!paymentMethodTypes.isEmpty, "At least one payment method type must be available.")
        paymentMethodTypeSelectorViewModel = PaymentMethodTypeSelectorViewModel(
            paymentMethodTypes: paymentMethodTypes,
            initialPaymentMethodType: previousCustomerInput?.paymentMethodType
        )
        linkAccount = LinkAccountContext.shared.account

        paymentMethodFormElement = PaymentSheetFormFactory(
            intent: intent,
            configuration: .paymentSheet(configuration),
            paymentMethod: paymentMethodTypeSelectorViewModel.selected,
            previousCustomerInput: previousCustomerInput,
            offerSaveToLinkWhenSupported: isLinkEnabled && !(linkAccount?.isRegistered ?? false),
            linkAccount: linkAccount
        ).make()
        paymentMethodFormElement.delegate = self

        addObservations()
    }

    deinit {
        LinkAccountContext.shared.removeObserver(self)
    }

    private func addObservations() {
        paymentMethodTypeSelectorViewModel.addObserver(self) { [weak self] in
            guard let self = self else { return }

            self.paymentMethodFormElement = self.makeElement(for: self.paymentMethodTypeSelectorViewModel.selected)
        }

        LinkAccountContext.shared.addObserver(self, selector: #selector(linkAccountChanged(_:)))
    }

    private func makeElement(
        for type: PaymentSheet.PaymentMethodType,
        previousCustomerInput: IntentConfirmParams? = nil
    ) -> PaymentMethodElement {
        // We are keeping usBankAccountInfo in memory to preserve state
        // if the user switches payment method types
        if type == .USBankAccount {
            return makeUSBankAccountFormElement(previousCustomerInput: previousCustomerInput)
        }

        let formElement = PaymentSheetFormFactory(
            intent: intent,
            configuration: .paymentSheet(configuration),
            paymentMethod: type,
            previousCustomerInput: previousCustomerInput,
            offerSaveToLinkWhenSupported: shouldOfferLinkSignup,
            linkAccount: linkAccount
        ).make()
        formElement.delegate = self
        return formElement
    }

    private func makeUSBankAccountFormElement(
        previousCustomerInput: IntentConfirmParams?
    ) -> PaymentMethodElement {
        guard let usBankAccountFormElement else {
            let formElement = PaymentSheetFormFactory(
                intent: intent,
                configuration: .paymentSheet(configuration),
                paymentMethod: .USBankAccount,
                previousCustomerInput: previousCustomerInput,
                offerSaveToLinkWhenSupported: shouldOfferLinkSignup,
                linkAccount: linkAccount
            ).make()

            guard let formElement = formElement as? USBankAccountPaymentMethodElement else {
                assertionFailure("Wrong type for usBankAccountFormElement")
                return FormElement(elements: [])
            }
            usBankAccountFormElement = formElement
            formElement.delegate = self
            formElement.presentingViewControllerDelegate = presentingViewControllerDelegate
            return formElement
        }
        return usBankAccountFormElement
    }

    @objc
    func linkAccountChanged(_ notification: Notification) {
        linkAccount = notification.object as? PaymentSheetLinkAccount
    }

    func handleCollectBankAccount(from viewController: UIViewController) {
        guard
            let usBankAccountPaymentMethodElement = paymentMethodFormElement as? USBankAccountPaymentMethodElement,
            let name = usBankAccountPaymentMethodElement.name,
            let email = usBankAccountPaymentMethodElement.email
        else {
            assertionFailure()
            return
        }

        let params = STPCollectBankAccountParams.collectUSBankAccountParams(
            with: name,
            email: email
        )
        let client = STPBankAccountCollector()
        let genericError = PaymentSheetError.accountLinkFailure

        let financialConnectionsCompletion: (FinancialConnectionsSDKResult?, LinkAccountSession?, NSError?) -> Void = {
            [weak self]
            result,
            _,
            error in
            guard error == nil else {
                self?.error = error
                return
            }
            guard let financialConnectionsResult = result else {
                self?.error = genericError
                return
            }

            self?.error = nil
            switch financialConnectionsResult {
            case .cancelled:
                break
            case .completed(let linkedBank):
                usBankAccountPaymentMethodElement.setLinkedBank(linkedBank)
            case .failed:
                self?.error = genericError
            }
        }
        switch intent {
        case .paymentIntent(let paymentIntent):
            client.collectBankAccountForPayment(
                clientSecret: paymentIntent.clientSecret,
                returnURL: configuration.returnURL,
                params: params,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        case .setupIntent(let setupIntent):
            client.collectBankAccountForSetup(
                clientSecret: setupIntent.clientSecret,
                returnURL: configuration.returnURL,
                params: params,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        case let .deferredIntent(elementsSession, intentConfig):
            let amount: Int?
            let currency: String?
            switch intentConfig.mode {
            case let .payment(amount: _amount, currency: _currency, _, _):
                amount = _amount
                currency = _currency
            case let .setup(currency: _currency, _):
                amount = nil
                currency = _currency
            }
            client.collectBankAccountForDeferredIntent(
                sessionId: elementsSession.sessionID,
                returnURL: configuration.returnURL,
                amount: amount,
                currency: currency,
                onBehalfOf: intentConfig.onBehalfOf,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        }
    }
}

// MARK: - ElementDelegate
extension AddPaymentMethodViewModel: ElementDelegate {
    func continueToNextField(element: Element) {
        notifier.notify()
    }

    func didUpdate(element: Element) {
        notifier.notify()
    }
}
