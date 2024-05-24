//
//  PaymentMethodFormViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/16/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class PaymentMethodFormViewController: UIViewController {
    let form: PaymentMethodElement
    let paymentMethodType: PaymentSheet.PaymentMethodType
    let configuration: PaymentSheet.Configuration

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
