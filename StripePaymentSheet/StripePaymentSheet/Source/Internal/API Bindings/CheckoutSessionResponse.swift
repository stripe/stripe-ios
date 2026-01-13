//
//  CheckoutSessionResponse.swift
//  StripePaymentSheet
//
//  Created by Porter Hampson on 1/12/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

final class CheckoutSessionResponse: NSObject {
    enum Mode: String {
        case payment
        case subscription
    }

    let currency: String
    let amount: Int
    let mode: Mode
    let setupFutureUsage: String?
    let captureMethod: String?
    let paymentMethodTypes: [String]
    let onBehalfOf: String?
    let paymentIntent: STPPaymentIntent?
    let setupIntent: STPSetupIntent?
    let paymentMethods: [STPPaymentMethod]
    let elementsSession: STPElementsSession?
    let allResponseFields: [AnyHashable: Any]

    init(
        currency: String,
        amount: Int,
        mode: Mode,
        setupFutureUsage: String?,
        captureMethod: String?,
        paymentMethodTypes: [String],
        onBehalfOf: String?,
        paymentIntent: STPPaymentIntent?,
        setupIntent: STPSetupIntent?,
        paymentMethods: [STPPaymentMethod],
        elementsSession: STPElementsSession?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.currency = currency
        self.amount = amount
        self.mode = mode
        self.setupFutureUsage = setupFutureUsage
        self.captureMethod = captureMethod
        self.paymentMethodTypes = paymentMethodTypes
        self.onBehalfOf = onBehalfOf
        self.paymentIntent = paymentIntent
        self.setupIntent = setupIntent
        self.paymentMethods = paymentMethods
        self.elementsSession = elementsSession
        self.allResponseFields = allResponseFields
        super.init()
    }
}

extension CheckoutSessionResponse: STPAPIResponseDecodable {
    static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response,
              let currency = response["currency"] as? String,
              let totalSummary = response["total_summary"] as? [String: Any],
              let amount = totalSummary["total"] as? Int,
              let modeString = response["mode"] as? String
        else { return nil }

        // Parse mode (subscription with invoice = payment)
        let mode: Mode
        if modeString == "subscription" && response["invoice"] != nil {
            mode = .payment
        } else {
            mode = Mode(rawValue: modeString) ?? .payment
        }

        // Parse optional fields
        let setupFutureUsage = response["setup_future_usage"] as? String
        let captureMethod = response["capture_method"] as? String
        let paymentMethodTypes = response["payment_method_types"] as? [String] ?? []
        let onBehalfOf = response["on_behalf_of"] as? String

        // Parse intent
        let paymentIntent = (response["payment_intent"] as? [AnyHashable: Any])
            .flatMap { STPPaymentIntent.decodedObject(fromAPIResponse: $0) }
        let setupIntent = (response["setup_intent"] as? [AnyHashable: Any])
            .flatMap { STPSetupIntent.decodedObject(fromAPIResponse: $0) }

        // Parse customer payment methods
        let customerDict = response["customer"] as? [String: Any]
        let paymentMethodsArray = customerDict?["payment_methods"] as? [[AnyHashable: Any]] ?? []
        let paymentMethods = paymentMethodsArray.compactMap {
            STPPaymentMethod.decodedObject(fromAPIResponse: $0)
        }

        // Parse elements session
        let elementsSession = (response["elements_session"] as? [AnyHashable: Any])
            .flatMap { STPElementsSession.decodedObject(fromAPIResponse: $0) }

        return CheckoutSessionResponse(
            currency: currency,
            amount: amount,
            mode: mode,
            setupFutureUsage: setupFutureUsage,
            captureMethod: captureMethod,
            paymentMethodTypes: paymentMethodTypes,
            onBehalfOf: onBehalfOf,
            paymentIntent: paymentIntent,
            setupIntent: setupIntent,
            paymentMethods: paymentMethods,
            elementsSession: elementsSession,
            allResponseFields: response
        ) as? Self
    }
}
