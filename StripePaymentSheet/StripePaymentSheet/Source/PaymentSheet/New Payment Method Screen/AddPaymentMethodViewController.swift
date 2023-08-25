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
}

/// This displays:
/// - A carousel of Payment Method types
/// - Input fields for the selected Payment Method type
/// For internal SDK use only
@objc(STP_Internal_AddPaymentMethodViewController)
class AddPaymentMethodViewController: UIViewController {
    // MARK: - Read-only Properties
    weak var delegate: AddPaymentMethodViewControllerDelegate?
    lazy var paymentMethodTypes: [PaymentSheet.PaymentMethodType] = {
        var paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            configuration: configuration,
            logAvailability: true
        )
        // TODO(yuki): Rewrite this when we support more EPMs
        if let epms = configuration.externalPaymentMethodConfiguration?.externalPaymentMethods,
           epms.contains("external_paypal") {
            paymentMethodTypes.append(.externalPayPal)
        }
        assert(!paymentMethodTypes.isEmpty, "At least one payment method type must be available.")
        return paymentMethodTypes
    }()
    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType {
        return paymentMethodTypesView.selected
    }
    var paymentOption: PaymentOption? {
        if let linkEnabledElement = paymentMethodFormElement as? LinkEnabledPaymentMethodElement {
            return linkEnabledElement.makePaymentOption()
        }

        var params = IntentConfirmParams(type: selectedPaymentMethodType)
        params = paymentMethodFormElement.applyDefaults(params: params)
        if let params = paymentMethodFormElement.updateParams(params: params) {
            // TODO(yuki): Hack to support external_paypal
            if selectedPaymentMethodType == .externalPayPal {
                return .externalPayPal(confirmParams: params)
            }
            return .new(confirmParams: params)
        }
        return nil
    }

    var linkAccount: PaymentSheetLinkAccount? = LinkAccountContext.shared.account {
        didSet {
            if oldValue?.sessionState != linkAccount?.sessionState {
                // TODO(link): This code ends up reloading the payment method form when `FlowController.update` is called, losing previous customer input.
                // I added this check to avoid reloading unless necessary but I'm not sure it works. When Link is re-enabled, we should make sure this works!
                updateFormElement()
            }
        }
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
        if selectedPaymentMethodType == .USBankAccount {
            if let usBankPaymentMethodElement = paymentMethodFormElement as? USBankAccountPaymentMethodElement {
                return usBankPaymentMethodElement.mandateString
            }
        }
        return nil
    }

    var overrideBuyButtonBehavior: OverrideableBuyButtonBehavior? {
        if selectedPaymentMethodType == .USBankAccount {
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

    private let intent: Intent
    private let configuration: PaymentSheet.Configuration
    var previousCustomerInput: IntentConfirmParams?
    private lazy var usBankAccountFormElement: USBankAccountPaymentMethodElement? = {
        // We are keeping usBankAccountInfo in memory to preserve state
        // if the user switches payment method types
        let paymentMethodElement = makeElement(for: selectedPaymentMethodType)
        if let usBankAccountPaymentMethodElement = paymentMethodElement as? USBankAccountPaymentMethodElement {
            usBankAccountPaymentMethodElement.presentingViewControllerDelegate = self
        } else {
            assertionFailure("Wrong type for usBankAccountFormElement")
        }
        return paymentMethodElement as? USBankAccountPaymentMethodElement
    }()
    private lazy var paymentMethodFormElement: PaymentMethodElement = {
        if selectedPaymentMethodType == .USBankAccount,
            let usBankAccountFormElement = usBankAccountFormElement
        {
            return usBankAccountFormElement
        }
        let element = makeElement(for: selectedPaymentMethodType)
        // Only use the previous customer input in the very first load, to avoid overwriting customer input
        previousCustomerInput = nil
        return element
    }()

    // MARK: - Views
    private lazy var paymentMethodDetailsView: UIView = {
        return paymentMethodFormElement.view
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
        view.addPinnedSubview(paymentMethodDetailsView)
        view.updateHeight()
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
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        if paymentMethodTypes == [.card] {
            paymentMethodTypesView.isHidden = true
        } else {
            paymentMethodTypesView.isHidden = false
        }
        updateUI()

        LinkAccountContext.shared.addObserver(self, selector: #selector(linkAccountChanged(_:)))
    }

    deinit {
        LinkAccountContext.shared.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let formElement = (paymentMethodFormElement as? PaymentMethodElementWrapper<FormElement>)?.element
            ?? paymentMethodFormElement
        if configuration.defaultBillingDetails == .init(),
            let addressSection = formElement.getAllSubElements()
                .compactMap({ $0 as? PaymentMethodElementWrapper<AddressSectionElement> }).first?.element
        {
            // If we're displaying an AddressSectionElement and we don't have default billing details, update it with the latest shipping details
            let delegate = addressSection.delegate
            addressSection.delegate = nil  // Stop didUpdate delegate calls to avoid laying out while we're being presented
            if let newShippingAddress = configuration.shippingDetails()?.address {
                addressSection.updateBillingSameAsShippingDefaultAddress(.init(newShippingAddress))
            } else {
                addressSection.updateBillingSameAsShippingDefaultAddress(.init())
            }
            addressSection.delegate = delegate
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendEventToSubviews(.viewDidAppear, from: view)
        delegate?.didUpdate(self)
    }

    // MARK: - Internal

    /// Returns true iff we could map the error to one of the displayed fields
    func setErrorIfNecessary(for error: Error?) -> Bool {
        // TODO
        return false
    }

    @objc
    func linkAccountChanged(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.linkAccount = notification.object as? PaymentSheetLinkAccount
        }
    }

    // MARK: - Private

    private func updateUI() {
        // Swap out the input view if necessary
        if paymentMethodFormElement.view !== paymentMethodDetailsView {
            let oldView = paymentMethodDetailsView
            let newView = paymentMethodFormElement.view
            self.paymentMethodDetailsView = newView

            // Add the new one and lay it out so it doesn't animate from a zero size
            paymentMethodDetailsContainerView.addPinnedSubview(newView)
            paymentMethodDetailsContainerView.layoutIfNeeded()
            newView.alpha = 0

            UISelectionFeedbackGenerator().selectionChanged()
            // Fade the new one in and the old one out
            animateHeightChange {
                self.paymentMethodDetailsContainerView.updateHeight()
                oldView.alpha = 0
                newView.alpha = 1
            } completion: { _ in
                // Remove the old one
                // This if check protects against a race condition where if you switch
                // between types with a re-used element (aka USBankAccountPaymentPaymentElement)
                // we swap the views before the animation completes
                if oldView !== self.paymentMethodDetailsView {
                    oldView.removeFromSuperview()
                }
            }
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
            linkAccount: linkAccount
        ).make()
        formElement.delegate = self
        return formElement
    }

    private func updateFormElement() {
        if selectedPaymentMethodType == .USBankAccount,
            let usBankAccountFormElement = usBankAccountFormElement
        {
            paymentMethodFormElement = usBankAccountFormElement
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
        }
    }

    func handleCollectBankAccount(from viewController: UIViewController) {
        guard
            let usBankAccountPaymentMethodElement = self.paymentMethodFormElement as? USBankAccountPaymentMethodElement,
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
            case .completed(let linkedBank):
                usBankAccountPaymentMethodElement.setLinkedBank(linkedBank)
            case .failed:
                self.delegate?.updateErrorLabel(for: genericError)
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
        delegate?.didUpdate(self)
        animateHeightChange()
    }
}

extension AddPaymentMethodViewController: PresentingViewControllerDelegate {
    func presentViewController(viewController: UIViewController, completion: (() -> Void)?) {
        self.present(viewController, animated: true, completion: completion)
    }
}
