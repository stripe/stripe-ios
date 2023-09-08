//
//  STPFixtures+PaymentSheet.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 8/11/23.
//

import Foundation
@_spi(STP) @testable import StripeCore
import StripePayments
@_spi(STP) @testable import StripePaymentSheet
import StripePaymentsTestUtils

public extension PaymentSheet.Configuration {
    /// Provides a Configuration that allows all pm types available
    static func _testValue_MostPermissive() -> Self {
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "https://foo.com"
        configuration.allowsDelayedPaymentMethods = true
        configuration.allowsPaymentMethodsRequiringShippingAddress = true
        configuration.applePay = .init(merchantId: "merchant id", merchantCountryCode: "US")
        return configuration
    }
}

extension STPElementsSession {
    static func _testCardValue() -> STPElementsSession {
        let elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        return elementsSession
    }

    static func _testValue(
        paymentMethodTypes: [String],
        flags: [String: Bool] = [:]
    ) -> STPElementsSession {
        var json = STPTestUtils.jsonNamed("ElementsSession")!
        json[jsonDict: "payment_method_preference"]?["ordered_payment_method_types"] = paymentMethodTypes
        json["flags"] = flags
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: json)!
        return elementsSession
    }
}
