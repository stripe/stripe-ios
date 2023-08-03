//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPMocks.swift
//  Stripe
//
//  Created by Ben Guo on 4/5/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation
import OCMock
import Stripe

class STPMocks: NSObject {
    /// A stateless customer context that always retrieves the same customer object.
    class func staticCustomerContext() -> STPCustomerContext? {
        return self.staticCustomerContext(
            with: STPFixtures.customerWithSingleCardTokenSource(),
            paymentMethods: [STPFixtures.paymentMethod()])
    }

    /// A static customer context that always retrieves the given customer and the given payment methods.
    /// Selecting a default source and attaching a source have no effect.
    class func staticCustomerContext(with customer: STPCustomer?, paymentMethods: [STPPaymentMethod]?) -> STPCustomerContext? {
        if #available(iOS 13.0, *) {
            return Testing_StaticCustomerContext_Objc.init(customer: customer, paymentMethods: paymentMethods)
        } else {
            return nil
        }
    }

    /// A PaymentConfiguration object with a fake publishable key and a fake apple
    /// merchant identifier that ignores the true value of [StripeAPI deviceSupportsApplePay]
    /// and bases its `applePayEnabled` value solely on what is set
    /// in `additionalPaymentOptions`
    class func paymentConfigurationWithApplePaySupportingDevice() -> STPPaymentConfiguration? {
        let config = STPFixtures.paymentConfiguration()
        config?.appleMerchantIdentifier = "fake_apple_merchant_id"
        let partialMock = OCMPartialMock(config)
        OCMStub(partialMock?.applePayEnabled()).andCall(partialMock, #selector(STPPaymentConfiguration.stpmock_applePayEnabled))
        return partialMock as? STPPaymentConfiguration
    }
}

extension STPPaymentConfiguration {
    /// Mock apple pay enabled response to just be based on setting and not hardware
    /// capability.
    /// `paymentConfigurationWithApplePaySupportingDevice` forwards calls to the
    /// real method to this stub
    @objc func stpmock_applePayEnabled() -> Bool {
        return applePayEnabled
    }
}