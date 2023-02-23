//
//  STPApplePayContext+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 11/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

typealias PaymentSheetResultCompletionBlock = ((PaymentSheetResult) -> Void)

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension STPApplePayContext {
    /// A shim class; ApplePayContext expects a protocol/delegate, but PaymentSheet uses closures.
    private class ApplePayContextClosureDelegate: NSObject, ApplePayContextDelegate {
        let completion: PaymentSheetResultCompletionBlock
        /// Retain this class until Apple Pay completes
        var selfRetainer: ApplePayContextClosureDelegate?
        let authorizationResultHandler:
            ((PKPaymentAuthorizationResult, @escaping ((PKPaymentAuthorizationResult) -> Void)) -> Void)?
        let clientSecret: String

        init(
            clientSecret: String,
            authorizationResultHandler: (
                (PKPaymentAuthorizationResult, @escaping ((PKPaymentAuthorizationResult) -> Void)) -> Void
            )?,
            completion: @escaping PaymentSheetResultCompletionBlock
        ) {
            self.completion = completion
            self.authorizationResultHandler = authorizationResultHandler
            self.clientSecret = clientSecret
            super.init()
            self.selfRetainer = self
        }

        func applePayContext(
            _ context: STPApplePayContext,
            didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod,
            paymentInformation: PKPayment,
            completion: @escaping STPIntentClientSecretCompletionBlock
        ) {
            completion(clientSecret, nil)
        }

        func applePayContext(
            _ context: STPApplePayContext,
            didCompleteWith status: STPApplePayContext.PaymentStatus,
            error: Error?
        ) {
            switch status {
            case .success:
                completion(.completed)
            case .error:
                completion(.failed(error: error!))
            case .userCancellation:
                completion(.canceled)
            }
            selfRetainer = nil
        }

        func applePayContext(
            _ context: STPApplePayContext,
            willCompleteWithResult authorizationResult: PKPaymentAuthorizationResult,
            handler: @escaping (PKPaymentAuthorizationResult) -> Void
        ) {
            if let authorizationResultHandler = authorizationResultHandler {
                authorizationResultHandler(authorizationResult) { result in
                    handler(result)
                }
            } else {
                handler(authorizationResult)
            }
        }
    }

    static func create(
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        completion: @escaping PaymentSheetResultCompletionBlock
    ) -> STPApplePayContext? {
        guard let applePay = configuration.applePay else {
            return nil
        }

        var paymentRequest = createPaymentRequest(intent: intent,
                                                  configuration: configuration,
                                                  applePay: applePay)

        if let paymentRequestHandler = configuration.applePay?.customHandlers?.paymentRequestHandler {
            paymentRequest = paymentRequestHandler(paymentRequest)
        }
        let delegate = ApplePayContextClosureDelegate(
            clientSecret: intent.clientSecret,
            authorizationResultHandler: configuration.applePay?.customHandlers?.authorizationResultHandler,
            completion: completion
        )
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: delegate) {
            applePayContext.shippingDetails = makeShippingDetails(from: configuration)
            applePayContext.apiClient = configuration.apiClient
            return applePayContext
        } else {
            // Delegate only deallocs when Apple Pay completes
            // Since Apple Pay failed to start, nil it out now
            delegate.selfRetainer = nil
            return nil
        }
    }

    private static func createPaymentRequest(
                intent: Intent,
                configuration: PaymentSheet.Configuration,
                applePay: PaymentSheet.ApplePayConfiguration
    ) -> PKPaymentRequest {
        func paymentRequest(with currency: String, amount: Int) -> PKPaymentRequest {
            var paymentRequest: PKPaymentRequest
            paymentRequest = StripeAPI.paymentRequest(
                withMerchantIdentifier: applePay.merchantId,
                country: applePay.merchantCountryCode,
                currency: currency
            )
            if let paymentSummaryItems = applePay.paymentSummaryItems {
                // Use the merchant supplied paymentSummaryItems
                paymentRequest.paymentSummaryItems = paymentSummaryItems
            } else {
                // Automatically configure paymentSummaryItems
                let decimalAmount = NSDecimalNumber.stp_decimalNumber(
                    withAmount: amount,
                    currency: currency
                )
                paymentRequest.paymentSummaryItems = [
                    PKPaymentSummaryItem(label: configuration.merchantDisplayName, amount: decimalAmount, type: .final),
                ]
            }
            return paymentRequest
        }

        func setupPaymentRequest() -> PKPaymentRequest {
            var paymentRequest: PKPaymentRequest
            paymentRequest = StripeAPI.paymentRequest(
                withMerchantIdentifier: applePay.merchantId,
                country: applePay.merchantCountryCode,
                currency: "USD"  // currency is required but unused
            )
            if let paymentSummaryItems = applePay.paymentSummaryItems {
                // Use the merchant supplied paymentSummaryItems
                paymentRequest.paymentSummaryItems = paymentSummaryItems
            } else {
                // Automatically configure paymentSummaryItems.
                paymentRequest.paymentSummaryItems = [
                    PKPaymentSummaryItem(label: "\(configuration.merchantDisplayName)", amount: .one, type: .pending),
                ]
            }

            return paymentRequest
        }

        switch intent {
        case .paymentIntent(let paymentIntent):
            return paymentRequest(with: paymentIntent.currency, amount: paymentIntent.amount)
        case .setupIntent:
            return setupPaymentRequest()
        case .deferredIntent(_, let intentConfig):
            switch intentConfig.mode {
            case .payment(let amount, let currency, _):
                return paymentRequest(with: currency, amount: amount)
            case .setup:
                return setupPaymentRequest()
            }
        }
    }
}

private func makeShippingDetails(from configuration: PaymentSheet.Configuration) -> StripeAPI.ShippingDetails? {
    guard let shippingDetails = configuration.shippingDetails(), let name = shippingDetails.name else {
        return nil
    }
    let address = shippingDetails.address
    return .init(
        address: .init(
            city: address.city,
            country: address.country,
            line1: address.line1,
            line2: address.line2,
            postalCode: address.postalCode,
            state: address.state
        ),
        name: name,
        phone: shippingDetails.phone
    )
}
