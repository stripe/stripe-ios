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
    let paymentMethodType: PaymentSheet.PaymentMethodType
    let configuration: PaymentSheet.Configuration
    weak var delegate: PaymentMethodFormViewControllerDelegate?
    var paymentOption: PaymentOption? {
        // TODO Copied from AddPaymentMethodViewController but this seems wrong; we shouldn't have such divergent paths for link and instant debits. Where is the setDefaultBillingDetailsIfNecessary call, for example?
        if let linkEnabledElement = form as? LinkEnabledPaymentMethodElement {
            return linkEnabledElement.makePaymentOption()
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
            if case .external(let paymentMethod) = paymentMethodType {
                return .external(paymentMethod: paymentMethod, billingDetails: params.paymentMethodParams.nonnil_billingDetails)
            }
            return .new(confirmParams: params)
        }
        return nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(type: PaymentSheet.PaymentMethodType, intent: Intent, previousCustomerInput: IntentConfirmParams?, configuration: PaymentSheet.Configuration, isLinkEnabled: Bool, delegate: PaymentMethodFormViewControllerDelegate) {
        self.paymentMethodType = type
        self.delegate = delegate
        self.configuration = configuration
        let shouldOfferLinkSignup: Bool = {
            guard isLinkEnabled && !intent.disableLinkSignup else {
                return false
            }

            let isAccountNotRegisteredOrMissing = LinkAccountContext.shared.account.flatMap({ !$0.isRegistered }) ?? true
            return isAccountNotRegisteredOrMissing && !UserDefaults.standard.customerHasUsedLink
        }()

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
        form.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addAndPinSubview(form.view)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        STPAnalyticsClient.sharedClient.logPaymentSheetFormShown(paymentMethodTypeIdentifier: paymentMethodType.identifier, apiClient: configuration.apiClient)
        sendEventToSubviews(.viewDidAppear, from: view)
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

    // TODO: Move handleCollect* methods from AddPaymentMethodViewController to here
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
