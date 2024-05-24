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

class PaymentMethodFormViewController: UIViewController {
    let form: PaymentMethodElement
    let paymentMethodType: PaymentSheet.PaymentMethodType
    let configuration: PaymentSheet.Configuration
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

    init(type: PaymentSheet.PaymentMethodType, form: PaymentMethodElement, configuration: PaymentSheet.Configuration) {
        self.paymentMethodType = type
        self.form = form
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
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
}
