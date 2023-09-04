//
//  STPFixtures+Swift.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 3/22/23.
//

import Foundation
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments

public extension STPFixtures {
    static func paymentMethodBillingDetails() -> STPPaymentMethodBillingDetails {
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"
        billingDetails.email = "foo@bar.com"
        billingDetails.phone = "5555555555"
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address?.line1 = "510 Townsend St."
        billingDetails.address?.line2 = "Line 2"
        billingDetails.address?.city = "San Francisco"
        billingDetails.address?.state = "CA"
        billingDetails.address?.country = "US"
        billingDetails.address?.postalCode = "94102"
        return billingDetails
    }

    static func paymentIntent(
        paymentMethodTypes: [String],
        orderedPaymentMethodTypes: [String]? = nil,
        setupFutureUsage: STPPaymentIntentSetupFutureUsage = .none,
        currency: String = "usd",
        status: STPPaymentIntentStatus = .requiresPaymentMethod,
        linkSettings: [AnyHashable: Any]? = nil,
        paymentMethodOptions: [AnyHashable: Any]? = nil
    ) -> STPPaymentIntent {
        var apiResponse: [AnyHashable: Any?] = [
            "id": "123",
            "client_secret": "sec",
            "amount": 10,
            "currency": currency,
            "status": STPPaymentIntentStatus.string(from: status),
            "livemode": false,
            "created": 1652736692.0,
            "payment_method_types": paymentMethodTypes,
            "setup_future_usage": setupFutureUsage.stringValue,
        ]
        if let orderedPaymentMethodTypes = orderedPaymentMethodTypes {
            apiResponse["ordered_payment_method_types"] = orderedPaymentMethodTypes
        }
        if let linkSettings = linkSettings {
            apiResponse["link_settings"] = linkSettings
        }
        if let paymentMethodOptions = paymentMethodOptions {
            apiResponse["payment_method_options"] = paymentMethodOptions
        }
        return STPPaymentIntent.decodeSTPPaymentIntentObject(
            fromAPIResponse: apiResponse as [AnyHashable: Any]
        )!
    }
}

public extension STPPaymentMethodParams {
    static func _testValidCardValue() -> STPPaymentMethodParams {
        return _testCardValue()
    }

    static func _testCardValue(number: String = "4242424242424242") -> STPPaymentMethodParams {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = number
        cardParams.cvc = "123"
        cardParams.expYear = (Calendar.current.dateComponents([.year], from: Date()).year! + 1) as NSNumber
        cardParams.expMonth = 01
        return STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)
    }
}
