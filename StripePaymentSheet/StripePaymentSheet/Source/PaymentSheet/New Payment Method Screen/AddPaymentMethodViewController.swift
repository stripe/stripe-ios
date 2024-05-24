//
//  AddPaymentMethodViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 10/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit
protocol AddPaymentMethodViewControllerDelegate: AnyObject {
    func didUpdate(_ viewController: AddPaymentMethodViewController)
    func shouldOfferLinkSignup(_ viewController: AddPaymentMethodViewController) -> Bool
    func updateErrorLabel(for: Error?)
}

enum OverrideableBuyButtonBehavior {
    case LinkUSBankAccount
    case instantDebits
}

/// This displays:
/// - A carousel of Payment Method types
/// - Input fields for the selected Payment Method type
/// For internal SDK use only
@objc(STP_Internal_AddPaymentMethodViewController)
class AddPaymentMethodViewController: UIViewController {
    enum Error: Swift.Error {
        case paymentMethodTypesEmpty
        case usBankAccountParamsMissing
        case instantDebitsDeferredIntentNotSupported
        case instantDebitsParamsMissing
    }

    // MARK: - Read-only Properties
    weak var delegate: AddPaymentMethodViewControllerDelegate?
    lazy var paymentMethodTypes: [PaymentSheet.PaymentMethodType] = {
        let paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            configuration: configuration,
            logAvailability: false
        )
        if paymentMethodTypes.isEmpty {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.paymentMethodTypesEmpty)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
        }
        stpAssert(!paymentMethodTypes.isEmpty, "At least one payment method type must be available.")
        return paymentMethodTypes
    }()
    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType {
        return paymentMethodTypesView.selected
    }
    var paymentOption: PaymentOption? {
        if let linkEnabledElement = paymentMethodFormElement as? LinkEnabledPaymentMethodElement {
            return linkEnabledElement.makePaymentOption()
        } else if let instantDebitsFormElement = paymentMethodFormElement as? InstantDebitsPaymentMethodElement {
            // we use `.instantDebits` payment method locally to display a
            // new button, but the actual payment method is `.link`, so
            // here we change it for the intent confirmation process
            let paymentMethodParams = STPPaymentMethodParams(type: .link)
            let intentConfirmParams = IntentConfirmParams(
                params: paymentMethodParams,
                type: .stripe(.link)
            )
            if let confirmParams = instantDebitsFormElement.updateParams(params: intentConfirmParams) {
                return .new(confirmParams: confirmParams)
            } else {
                return nil
            }
        }

        let params = IntentConfirmParams(type: selectedPaymentMethodType)
        params.setDefaultBillingDetailsIfNecessary(for: configuration)
        if let params = paymentMethodFormElement.updateParams(params: params) {
            if case .external(let paymentMethod) = selectedPaymentMethodType {
                return .external(paymentMethod: paymentMethod, billingDetails: params.paymentMethodParams.nonnil_billingDetails)
            }
            return .new(confirmParams: params)
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
        case .instantDebits:
            return instantDebitsFormElement?.enableCTA ?? false
        }
    }

    var bottomNoticeAttributedString: NSAttributedString? {
        if selectedPaymentMethodType == .stripe(.USBankAccount) {
            if let usBankPaymentMethodElement = paymentMethodFormElement as? USBankAccountPaymentMethodElement {
                return usBankPaymentMethodElement.mandateString
            }
        } else if selectedPaymentMethodType == .stripe(.instantDebits) {
            if let instantDebitsLinkedBank = paymentMethodFormElement as? InstantDebitsPaymentMethodElement {
                return instantDebitsLinkedBank.mandateString
            }
        }
        return nil
    }

    var overrideBuyButtonBehavior: OverrideableBuyButtonBehavior? {
        if selectedPaymentMethodType == .stripe(.USBankAccount) {
            if
                let paymentOption = paymentOption,
                case .new = paymentOption
            {
                return nil  // already have PaymentOption
            } else {
                return .LinkUSBankAccount
            }
        } else if selectedPaymentMethodType == .stripe(.instantDebits) {
            // only override buy button (show "Continue") IF we don't have a linked bank
            return (instantDebitsFormElement?.getLinkedBank() != nil) ? nil : .instantDebits
        }
        return nil
    }

    private let intent: Intent
    private let configuration: PaymentSheet.Configuration
    var previousCustomerInput: IntentConfirmParams?

    // We are keeping usBankAccountInfo in memory to preserve state if the user switches payment method types
    private var usBankAccountFormElement: USBankAccountPaymentMethodElement?
    // We are keeping `instantDebitsFormElement` in memory to preserve state if the user switches payment method types
    private var instantDebitsFormElement: InstantDebitsPaymentMethodElement?

    private lazy var paymentMethodFormElement: PaymentMethodElement = {
        if selectedPaymentMethodType == .stripe(.USBankAccount) {
            if let usBankAccountFormElement {
                // Use the cached form instead of creating a new one
                return usBankAccountFormElement
            } else {
                // Cache the form
                let element = makeElement(for: .stripe(.USBankAccount))
                usBankAccountFormElement = element as? USBankAccountPaymentMethodElement
                return element
            }
        } else if selectedPaymentMethodType == .stripe(.instantDebits) {
            if let instantDebitsFormElement {
                // Use the cached form instead of creating a new one
                return instantDebitsFormElement
            } else {
                // Cache the form
                let element = makeElement(for: .stripe(.instantDebits))
                instantDebitsFormElement = element as? InstantDebitsPaymentMethodElement
                return element
            }
        }
        let element = makeElement(for: selectedPaymentMethodType)
        // Only use the previous customer input in the very first load, to avoid overwriting customer input
        previousCustomerInput = nil
        return element
    }()

    // MARK: - Views
    private var paymentMethodDetailsView: UIView {
        return paymentMethodFormViewController.view
    }
    private lazy var paymentMethodFormViewController: PaymentMethodFormViewController = {
        return PaymentMethodFormViewController(type: selectedPaymentMethodType, form: paymentMethodFormElement, configuration: configuration)
    }()
    private lazy var paymentMethodTypesView: PaymentMethodTypeCollectionView = {
        let view = PaymentMethodTypeCollectionView(
            paymentMethodTypes: paymentMethodTypes,
            initialPaymentMethodType: previousCustomerInput?.paymentMethodType,
            appearance: configuration.appearance,
            isPaymentSheet: true,
            delegate: self
        )
        return view
    }()
    private lazy var paymentMethodDetailsContainerView: DynamicHeightContainerView = {
        // when displaying link, we aren't in the bottom/payment sheet so pin to top for height changes
        let view = DynamicHeightContainerView(pinnedDirection: configuration.linkPaymentMethodsOnly ? .top : .bottom)
        view.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        return view
    }()

    // MARK: - Inits
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        previousCustomerInput: IntentConfirmParams? = nil,
        delegate: AddPaymentMethodViewControllerDelegate? = nil
    ) {
        self.configuration = configuration
        self.intent = intent
        self.previousCustomerInput = previousCustomerInput
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background

        let stackView = UIStackView(arrangedSubviews: [
            paymentMethodTypesView, paymentMethodDetailsContainerView,
        ])
        stackView.bringSubviewToFront(paymentMethodTypesView)
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addAndPinSubview(stackView)
        if paymentMethodTypes == [.stripe(.card)] {
            paymentMethodTypesView.isHidden = true
        } else {
            paymentMethodTypesView.isHidden = false
        }
        updateUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.didUpdate(self)
    }

    // MARK: - Internal

    /// Returns true iff we could map the error to one of the displayed fields
    func setErrorIfNecessary(for error: Swift.Error?) -> Bool {
        // TODO
        return false
    }

    // MARK: - Private

    private func updateUI() {
        // Swap out the input view if necessary
        if paymentMethodFormElement !== paymentMethodDetailsView {
#if !canImport(CompositorServices)
            UISelectionFeedbackGenerator().selectionChanged()
#endif
            paymentMethodFormViewController = PaymentMethodFormViewController(type: selectedPaymentMethodType, form: paymentMethodFormElement, configuration: configuration)
            switchContentIfNecessary(to: paymentMethodFormViewController, containerView: paymentMethodDetailsContainerView)
        }
    }

    private func makeElement(for type: PaymentSheet.PaymentMethodType) -> PaymentMethodElement {
        let offerSaveToLinkWhenSupported = delegate?.shouldOfferLinkSignup(self) ?? false

        let formElement = PaymentSheetFormFactory(
            intent: intent,
            configuration: .paymentSheet(configuration),
            paymentMethod: type,
            previousCustomerInput: previousCustomerInput,
            offerSaveToLinkWhenSupported: offerSaveToLinkWhenSupported,
            linkAccount: LinkAccountContext.shared.account
        ).make()
        formElement.delegate = self
        return formElement
    }

    private func updateFormElement() {
        if selectedPaymentMethodType == .stripe(.USBankAccount) {
            if let usBankAccountFormElement {
                // Use the cached form instead of creating a new one
                paymentMethodFormElement = usBankAccountFormElement
            } else {
                // Cache the form
                paymentMethodFormElement = makeElement(for: .stripe(.USBankAccount))
                usBankAccountFormElement = paymentMethodFormElement as? USBankAccountPaymentMethodElement
            }
        } else if selectedPaymentMethodType == .stripe(.instantDebits) {
            if let instantDebitsFormElement {
                // Use the cached form instead of creating a new one
                paymentMethodFormElement = instantDebitsFormElement
            } else {
                // Cache the form
                paymentMethodFormElement = makeElement(for: .stripe(.instantDebits))
                instantDebitsFormElement = paymentMethodFormElement as? InstantDebitsPaymentMethodElement
            }
        } else {
            paymentMethodFormElement = makeElement(for: selectedPaymentMethodType)
        }
        updateUI()
        sendEventToSubviews(.viewDidAppear, from: view)
    }

    func didTapCallToActionButton(behavior: OverrideableBuyButtonBehavior, from viewController: UIViewController) {
        switch behavior {
        case .LinkUSBankAccount:
            handleCollectBankAccount(from: viewController)
        case .instantDebits:
            handleCollectInstantDebits(from: viewController)
        }
    }

    func handleCollectBankAccount(from viewController: UIViewController) {
        guard
            let usBankAccountPaymentMethodElement = self.paymentMethodFormElement as? USBankAccountPaymentMethodElement,
            let name = usBankAccountPaymentMethodElement.name,
            let email = usBankAccountPaymentMethodElement.email
        else {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.usBankAccountParamsMissing)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
            return
        }

        let params = STPCollectBankAccountParams.collectUSBankAccountParams(
            with: name,
            email: email
        )
        let client = STPBankAccountCollector()
        let genericError = PaymentSheetError.accountLinkFailure

        let financialConnectionsCompletion: (FinancialConnectionsSDKResult?, LinkAccountSession?, NSError?) -> Void = {
            result,
            _,
            error in
            if error != nil {
                self.delegate?.updateErrorLabel(for: genericError)
                return
            }
            guard let financialConnectionsResult = result else {
                self.delegate?.updateErrorLabel(for: genericError)
                return
            }

            switch financialConnectionsResult {
            case .cancelled:
                break
            case .completed(let completedResult):
                if case .financialConnections(let linkedBank) = completedResult {
                    usBankAccountPaymentMethodElement.setLinkedBank(linkedBank)
                } else {
                    self.delegate?.updateErrorLabel(for: genericError)
                }
            case .failed:
                self.delegate?.updateErrorLabel(for: genericError)
            }
        }
        switch intent {
        case .paymentIntent(_, let paymentIntent):
            client.collectBankAccountForPayment(
                clientSecret: paymentIntent.clientSecret,
                returnURL: configuration.returnURL,
                onEvent: nil,
                params: params,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        case .setupIntent(_, let setupIntent):
            client.collectBankAccountForSetup(
                clientSecret: setupIntent.clientSecret,
                returnURL: configuration.returnURL,
                onEvent: nil,
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
                onEvent: nil,
                amount: amount,
                currency: currency,
                onBehalfOf: intentConfig.onBehalfOf,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        }
    }

    private func handleCollectInstantDebits(from viewController: UIViewController) {
        guard
            let instantDebitsPaymentMethodElement = self.paymentMethodFormElement as? InstantDebitsPaymentMethodElement,
            let email = instantDebitsPaymentMethodElement.email
        else {
            let errorAnalytic = ErrorAnalytic(
                event: .unexpectedPaymentSheetError,
                error: Error.instantDebitsParamsMissing
            )
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
            return
        }

        let params = STPCollectBankAccountParams.collectInstantDebitsParams(
            email: email
        )
        let client = STPBankAccountCollector()
        let genericError = PaymentSheetError.accountLinkFailure

        let financialConnectionsCompletion: (
            FinancialConnectionsSDKResult?,
            LinkAccountSession?,
            NSError?
        ) -> Void = { result, _, error in
            if error != nil {
                self.delegate?.updateErrorLabel(for: genericError)
                return
            }
            guard let financialConnectionsResult = result else {
                self.delegate?.updateErrorLabel(for: genericError)
                return
            }
            switch financialConnectionsResult {
            case .completed(let completedResult):
                if case .instantDebits(let instantDebitsLinkedBank) = completedResult {
                    instantDebitsPaymentMethodElement.setLinkedBank(instantDebitsLinkedBank)
                } else {
                    self.delegate?.updateErrorLabel(for: genericError)
                }
            case .cancelled:
                break
            case .failed:
                self.delegate?.updateErrorLabel(for: genericError)
            }
        }
        switch intent {
        case .paymentIntent(_, let paymentIntent):
            client.collectBankAccountForPayment(
                clientSecret: paymentIntent.clientSecret,
                returnURL: configuration.returnURL,
                onEvent: nil,
                params: params,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        case .setupIntent(_, let setupIntent):
            client.collectBankAccountForSetup(
                clientSecret: setupIntent.clientSecret,
                returnURL: configuration.returnURL,
                onEvent: nil,
                params: params,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        case .deferredIntent: // not supported
            let errorAnalytic = ErrorAnalytic(
                event: .unexpectedPaymentSheetError,
                error: Error.instantDebitsDeferredIntentNotSupported
            )
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
        }
    }

    func clearTextFields() {
        paymentMethodFormElement.clearTextFields()
    }
}

// MARK: - PaymentMethodTypeCollectionViewDelegate

extension AddPaymentMethodViewController: PaymentMethodTypeCollectionViewDelegate {
    func didUpdateSelection(_ paymentMethodTypeCollectionView: PaymentMethodTypeCollectionView) {
        updateFormElement()
        delegate?.didUpdate(self)
    }
}

// MARK: - ElementDelegate

extension AddPaymentMethodViewController: ElementDelegate {
    func continueToNextField(element: Element) {
        delegate?.didUpdate(self)
    }

    func didUpdate(element: Element) {
        STPAnalyticsClient.sharedClient.logPaymentSheetFormInteracted(paymentMethodTypeIdentifier: selectedPaymentMethodType.identifier)
        delegate?.didUpdate(self)
        animateHeightChange()
    }
}

extension AddPaymentMethodViewController: PresentingViewControllerDelegate {
    func presentViewController(viewController: UIViewController, completion: (() -> Void)?) {
        self.present(viewController, animated: true, completion: completion)
    }
}
