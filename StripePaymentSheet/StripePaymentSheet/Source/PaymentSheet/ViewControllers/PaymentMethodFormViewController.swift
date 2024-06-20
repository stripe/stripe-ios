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
    let paymentMethodType: PaymentSheet.PaymentMethodType
    let configuration: PaymentSheet.Configuration
    weak var delegate: PaymentMethodFormViewControllerDelegate?
    var paymentOption: PaymentOption? {
        // TODO Copied from AddPaymentMethodViewController but this seems wrong; we shouldn't have such divergent paths for link and instant debits. Where is the setDefaultBillingDetailsIfNecessary call, for example?
        if let linkEnabledElement = form as? LinkEnabledPaymentMethodElement {
            return linkEnabledElement.makePaymentOption(intent: intent)
        } else if let instantDebitsFormElement = form as? InstantDebitsPaymentMethodElement {
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

        let params = IntentConfirmParams(type: paymentMethodType)
        params.setDefaultBillingDetailsIfNecessary(for: configuration)
        if let params = form.updateParams(params: params) {
            params.setAllowRedisplay(for: intent.elementsSession.savePaymentMethodConsentBehavior())
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(type: PaymentSheet.PaymentMethodType, intent: Intent, previousCustomerInput: IntentConfirmParams?, configuration: PaymentSheet.Configuration, isLinkEnabled: Bool, headerView: UIView?, delegate: PaymentMethodFormViewControllerDelegate) {
        self.paymentMethodType = type
        self.intent = intent
        self.delegate = delegate
        self.configuration = configuration
        self.headerView = headerView
        let shouldOfferLinkSignup: Bool = {
            guard isLinkEnabled && !intent.disableLinkSignup else {
                return false
            }

            let isAccountNotRegisteredOrMissing = LinkAccountContext.shared.account.flatMap({ !$0.isRegistered }) ?? true
            return isAccountNotRegisteredOrMissing && !UserDefaults.standard.customerHasUsedLink
        }()

        // TODO: Inject form cache, make it come from LoadResult, maybe move cache to FormFactory so that shouldDisplayForm checks don't initialize this vc and set the form delegate
        if let form = Self.formCache[type] {
            self.form = form
        } else {
            self.form = PaymentSheetFormFactory(
                intent: intent,
                configuration: .paymentSheet(configuration),
                paymentMethod: paymentMethodType,
                previousCustomerInput: previousCustomerInput,
                offerSaveToLinkWhenSupported: shouldOfferLinkSignup,
                linkAccount: LinkAccountContext.shared.account
            ).make()
            Self.formCache[type] = form
        }

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addAndPinSubview(formStackView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        STPAnalyticsClient.sharedClient.logPaymentSheetFormShown(paymentMethodTypeIdentifier: paymentMethodType.identifier, apiClient: configuration.apiClient)
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
        STPAnalyticsClient.sharedClient.logPaymentSheetFormInteracted(paymentMethodTypeIdentifier: paymentMethodType.identifier)
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

extension PaymentMethodFormViewController {
    /// This caches forms for payment methods so that customers don't have to re-enter details
    /// This class expects the formCache to be invalidated (cleared) when we load PaymentSheet; we assume the form generated for a given PM type _does not change_ at any point after load.
    static var formCache: [PaymentSheet.PaymentMethodType: PaymentMethodElement] = [:]

    static func clearFormCache() {
        formCache = [:]
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

    private var shouldOverridePrimaryButton: Bool {
        if paymentMethodType == .stripe(.USBankAccount) {
            if case .new = paymentOption {
                return false  // already have PaymentOption
            } else {
                return true
            }
        } else if paymentMethodType == .stripe(.instantDebits) {
            // only override buy button (show "Continue") IF we don't have a linked bank
            return instantDebitsFormElement?.getLinkedBank() == nil
        }
        return false
    }

    var overridePrimaryButtonState: OverridePrimaryButtonState? {
        guard shouldOverridePrimaryButton else { return nil }
        let isEnabled: Bool = {
            if paymentMethodType == .stripe(.USBankAccount) && usBankAccountFormElement?.canLinkAccount ?? false {
                true
            } else if paymentMethodType == .stripe(.instantDebits) && instantDebitsFormElement?.enableCTA ?? false {
                true
            } else {
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
        case .stripe(.instantDebits):
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
                    usBankAccountFormElement.setLinkedBank(linkedBank)
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
        case .paymentIntent(_, let paymentIntent):
            client.collectBankAccountForPayment(
                clientSecret: paymentIntent.clientSecret,
                returnURL: configuration.returnURL,
                additionalParameters: additionalParameters,
                onEvent: nil,
                params: params,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        case .setupIntent(_, let setupIntent):
            client.collectBankAccountForSetup(
                clientSecret: setupIntent.clientSecret,
                returnURL: configuration.returnURL,
                additionalParameters: additionalParameters,
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
                additionalParameters: additionalParameters,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        }
    }

    private func handleCollectInstantDebits(from viewController: UIViewController) {
        guard
            let instantDebitsFormElement,
            let email = instantDebitsFormElement.email
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
        case .paymentIntent(_, let paymentIntent):
            client.collectBankAccountForPayment(
                clientSecret: paymentIntent.clientSecret,
                returnURL: configuration.returnURL,
                additionalParameters: additionalParameters,
                onEvent: nil,
                params: params,
                from: viewController,
                financialConnectionsCompletion: financialConnectionsCompletion
            )
        case .setupIntent(_, let setupIntent):
            client.collectBankAccountForSetup(
                clientSecret: setupIntent.clientSecret,
                returnURL: configuration.returnURL,
                additionalParameters: additionalParameters,
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
