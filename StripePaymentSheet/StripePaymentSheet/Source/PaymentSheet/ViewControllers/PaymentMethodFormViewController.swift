//
//  PaymentMethodFormViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/16/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

protocol PaymentMethodFormViewControllerDelegate: AnyObject {
    func didUpdate(_ viewController: PaymentMethodFormViewController)
    func updateErrorLabel(for error: Error?)
}

class PaymentMethodFormViewController: UIViewController {
    let form: PaymentMethodElement
    let intent: Intent
    let elementsSession: STPElementsSession
    let paymentMethodType: PaymentSheet.PaymentMethodType
    let configuration: PaymentElementConfiguration
    let analyticsHelper: PaymentSheetAnalyticsHelper
    weak var delegate: PaymentMethodFormViewControllerDelegate?
    var paymentOption: PaymentOption? {
        let params = IntentConfirmParams(type: paymentMethodType)
        params.setDefaultBillingDetailsIfNecessary(for: configuration)

        if let params = form.updateParams(params: params) {
            if let linkInlineSignupElement = form.getAllUnwrappedSubElements().compactMap({ $0 as? LinkInlineSignupElement }).first {
                switch linkInlineSignupElement.action {
                case .signupAndPay(let account, let phoneNumber, let legalName):
                    return .link(
                        option: .signUp(
                            account: account,
                            phoneNumber: phoneNumber,
                            consentAction: linkInlineSignupElement.viewModel.consentAction,
                            legalName: legalName,
                            intentConfirmParams: params
                        )
                    )
                case .continueWithoutLink:
                    return .new(confirmParams: params)
                case .none:
                    // Link is optional when in textFieldOnly mode
                    if linkInlineSignupElement.viewModel.mode != .checkbox {
                        return .new(confirmParams: params)
                    }
                    return nil
                }
            }

            if case .external(let paymentMethod) = paymentMethodType {
                return .external(paymentMethod: paymentMethod, billingDetails: params.paymentMethodParams.nonnil_billingDetails)
            }
            return .new(confirmParams: params)
        }
        return nil
    }

    lazy var formStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerView, form.view].compactMap { $0 })
        stackView.spacing = 24
        stackView.axis = .vertical
        return stackView
    }()
    let headerView: UIView?

    /// This caches forms for payment methods so that customers don't have to re-enter details
    /// This assumes the form generated for a given PM type _does not change_ at any point after load.
    let formCache: PaymentMethodFormCache

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(
        type: PaymentSheet.PaymentMethodType,
        intent: Intent,
        elementsSession: STPElementsSession,
        previousCustomerInput: IntentConfirmParams?,
        formCache: PaymentMethodFormCache,
        configuration: PaymentElementConfiguration,
        headerView: UIView?,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        delegate: PaymentMethodFormViewControllerDelegate
    ) {
        self.paymentMethodType = type
        self.intent = intent
        self.elementsSession = elementsSession
        self.delegate = delegate
        self.configuration = configuration
        self.headerView = headerView
        self.formCache = formCache
        if let form = self.formCache[type] {
            self.form = form
        } else {
            self.form = PaymentSheetFormFactory(
                intent: intent,
                elementsSession: elementsSession,
                configuration: .paymentSheet(configuration),
                paymentMethod: paymentMethodType,
                previousCustomerInput: previousCustomerInput,
                linkAccount: LinkAccountContext.shared.account,
                analyticsHelper: analyticsHelper
            ).make()
            self.formCache[type] = form
        }
        self.analyticsHelper = analyticsHelper
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addAndPinSubview(formStackView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        analyticsHelper.logFormShown(paymentMethodTypeIdentifier: paymentMethodType.identifier)
        sendEventToSubviews(.viewDidAppear, from: view)
        // The form is cached and could have been shared across other instance of PaymentMethodFormViewController after this instance was initialized, so we set the delegate in viewDidAppear to ensure that the form's delegate is up to date.
        form.delegate = self
        delegate?.didUpdate(self) // notify delegate in case of any mandates being displayed
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let formElement = (form as? PaymentMethodElementWrapper<FormElement>)?.element ?? form
        if
            configuration.defaultBillingDetails == .init(),
            let addressSection = formElement.getAllUnwrappedSubElements()
                .compactMap({ $0 as? AddressSectionElement }).first
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

    // MARK: - Helpers
    func clearTextFields() {
        form.clearTextFields()
    }
}

// MARK: - ElementDelegate

extension PaymentMethodFormViewController: ElementDelegate {
    func continueToNextField(element: Element) {
        delegate?.didUpdate(self)
    }

    func didUpdate(element: Element) {
        analyticsHelper.logFormInteracted(paymentMethodTypeIdentifier: paymentMethodType.identifier)
        delegate?.didUpdate(self)
        animateHeightChange()
    }
}

// MARK: - PresentingViewControllerDelegate

extension PaymentMethodFormViewController: PresentingViewControllerDelegate {
    func presentViewController(viewController: UIViewController, completion: (() -> Void)?) {
        present(viewController, animated: true, completion: completion)
    }
}

// MARK: - Form cache

/// This caches forms for payment methods so that customers don't have to re-enter details.
/// ⚠️ Make sure you invalidate the cache appropriately e.g. changing the Intent should invalidate the cache.
class PaymentMethodFormCache {
    private var cache: [PaymentSheet.PaymentMethodType: PaymentMethodElement] = [:]

    subscript(paymentMethodType: PaymentSheet.PaymentMethodType) -> PaymentMethodElement? {
        get {
            return cache[paymentMethodType]
        }
        set {
            cache[paymentMethodType] = newValue
        }
    }
}

// MARK: - US Bank Account and Link Instant Debits

struct OverridePrimaryButtonState {
    let enabled: Bool
    let ctaType: ConfirmButton.CallToActionType
}

extension PaymentMethodFormViewController {
    enum Error: Swift.Error {
        case usBankAccountParamsMissing
        case instantDebitsDeferredIntentNotSupported
        case instantDebitsParamsMissing
    }

    private var usBankAccountFormElement: USBankAccountPaymentMethodElement? { form as? USBankAccountPaymentMethodElement }
    private var instantDebitsFormElement: InstantDebitsPaymentMethodElement? { form as? InstantDebitsPaymentMethodElement }

    private var elementsSessionContext: ElementsSessionContext {
        let intentId: ElementsSessionContext.IntentID? = {
            switch intent {
            case .paymentIntent(let paymentIntent):
                return .payment(paymentIntent.stripeId)
            case .setupIntent(let setupIntent):
                return .setup(setupIntent.stripeID)
            case .deferredIntent:
                return nil
            }
        }()

        let defaultPhoneNumber = configuration.defaultBillingDetails.phone
        let defaultUnformattedPhoneNumber: String? = {
            guard let defaultPhoneNumber else { return nil }
            return PhoneNumber.fromE164(defaultPhoneNumber)?.number
        }()
        let prefillDetails = ElementsSessionContext.PrefillDetails(
            email: instantDebitsFormElement?.email ?? configuration.defaultBillingDetails.email,
            formattedPhoneNumber: instantDebitsFormElement?.phone ?? defaultPhoneNumber,
            unformattedPhoneNumber: instantDebitsFormElement?.phoneElement?.phoneNumber?.number ?? defaultUnformattedPhoneNumber,
            countryCode: instantDebitsFormElement?.phoneElement?.selectedCountryCode
        )
        let linkMode = elementsSession.linkSettings?.linkMode
        let billingAddress: BillingAddress? = {
            if configuration.billingDetailsCollectionConfiguration.address == .full {
                return instantDebitsFormElement?.billingAddress
            } else if configuration.billingDetailsCollectionConfiguration.name == .always {
                return BillingAddress(name: instantDebitsFormElement?.name)
            } else {
                return nil
            }
        }()

        let billingDetails = ElementsSessionContext.BillingDetails(
            name: instantDebitsFormElement?.name,
            email: instantDebitsFormElement?.email,
            phone: instantDebitsFormElement?.phone,
            address: ElementsSessionContext.BillingDetails.Address(from: billingAddress)
        )
        return ElementsSessionContext(
            amount: intent.amount,
            currency: intent.currency,
            prefillDetails: prefillDetails,
            intentId: intentId,
            linkMode: linkMode,
            billingAddress: billingAddress,
            billingDetails: billingDetails
        )
    }

    private var shouldOverridePrimaryButton: Bool {
        if paymentMethodType == .stripe(.USBankAccount) {
            if case .new = paymentOption {
                return false  // already have PaymentOption
            } else {
                return true
            }
        } else if paymentMethodType == .instantDebits || paymentMethodType == .linkCardBrand {
            // only override buy button (show "Continue") IF we don't have a linked bank
            return instantDebitsFormElement?.getLinkedBank() == nil
        }
        return false
    }

    var overridePrimaryButtonState: OverridePrimaryButtonState? {
        guard shouldOverridePrimaryButton else { return nil }
        let isEnabled: Bool = {
            switch paymentMethodType {
            case .stripe(let paymentMethod):
                paymentMethod == .USBankAccount && (usBankAccountFormElement?.canLinkAccount ?? false)
            case .instantDebits, .linkCardBrand:
                instantDebitsFormElement?.enableCTA ?? false
            default:
                false
            }
        }()
        return .init(
            enabled: isEnabled,
            ctaType: ConfirmButton.CallToActionType.customWithLock(title: String.Localized.continue)
        )
    }

    var bottomNoticeAttributedString: NSAttributedString? {
        if let usBankAccountFormElement {
            return usBankAccountFormElement.mandateString
        }
        if let instantDebitsFormElement {
            return instantDebitsFormElement.mandateString
        }
        return nil
    }

    func didTapCallToActionButton(from viewController: UIViewController) {
        switch paymentMethodType {
        case .stripe(.USBankAccount):
            handleCollectBankAccount(from: viewController)
        case .instantDebits, .linkCardBrand:
            handleCollectInstantDebits(from: viewController)
        default:
            return
        }
    }

    func handleCollectBankAccount(from viewController: UIViewController) {
        guard
            let usBankAccountFormElement,
            let name = usBankAccountFormElement.name,
            let email = usBankAccountFormElement.email
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

        let financialConnectionsCompletion: STPBankAccountCollector.CollectBankAccountCompletionBlock = { result, _, error in
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
                    usBankAccountFormElement.linkedBank = linkedBank
                } else {
                    self.delegate?.updateErrorLabel(for: genericError)
                }
            case .failed:
                self.delegate?.updateErrorLabel(for: genericError)
            }
        }
        let additionalParameters: [String: Any] = [
            "hosted_surface": "payment_element",
        ]
        switch intent {
        case .paymentIntent(let paymentIntent):
            client.collectBankAccountForPayment(
                clientSecret: paymentIntent.clientSecret,
                returnURL: configuration.returnURL,
                additionalParameters: additionalParameters,
                elementsSessionContext: elementsSessionContext,
                onEvent: nil,
                params: params,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        case .setupIntent(let setupIntent):
            client.collectBankAccountForSetup(
                clientSecret: setupIntent.clientSecret,
                returnURL: configuration.returnURL,
                additionalParameters: additionalParameters,
                elementsSessionContext: elementsSessionContext,
                onEvent: nil,
                params: params,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        case let .deferredIntent(intentConfig):
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
                additionalParameters: additionalParameters,
                elementsSessionContext: elementsSessionContext,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        }
    }

    private func handleCollectInstantDebits(from viewController: UIViewController) {
        guard let instantDebitsFormElement else {
            let errorAnalytic = ErrorAnalytic(
                event: .unexpectedPaymentSheetError,
                error: Error.instantDebitsParamsMissing
            )
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
            return
        }

        let params = STPCollectBankAccountParams.collectInstantDebitsParams(
            email: instantDebitsFormElement.email
        )
        let client = STPBankAccountCollector()
        let genericError = PaymentSheetError.accountLinkFailure

        let financialConnectionsCompletion: STPBankAccountCollector.CollectBankAccountCompletionBlock = { result, _, error in
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
                    instantDebitsFormElement.setLinkedBank(instantDebitsLinkedBank)
                } else {
                    self.delegate?.updateErrorLabel(for: genericError)
                }
            case .cancelled:
                break
            case .failed:
                self.delegate?.updateErrorLabel(for: genericError)
            }
        }
        let additionalParameters: [String: Any] = [
            "product": "instant_debits",
            "attach_required": true,
            "hosted_surface": "payment_element",
        ]
        switch intent {
        case .paymentIntent(let paymentIntent):
            client.collectBankAccountForPayment(
                clientSecret: paymentIntent.clientSecret,
                returnURL: configuration.returnURL,
                additionalParameters: additionalParameters,
                elementsSessionContext: elementsSessionContext,
                onEvent: nil,
                params: params,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        case .setupIntent(let setupIntent):
            client.collectBankAccountForSetup(
                clientSecret: setupIntent.clientSecret,
                returnURL: configuration.returnURL,
                additionalParameters: additionalParameters,
                elementsSessionContext: elementsSessionContext,
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
}
