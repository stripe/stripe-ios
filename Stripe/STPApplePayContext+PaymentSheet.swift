//
//  STPApplePayContext+PaymentSheet.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeApplePay

typealias PaymentSheetResultCompletionBlock = ((PaymentSheetResult) -> Void)

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension STPApplePayContext {
    /// A shim class; ApplePayContext expects a protocol/delegate, but PaymentSheet uses closures.
    private class ApplePayContextClosureDelegate: NSObject, STPApplePayContextDelegate {
        let completion: PaymentSheetResultCompletionBlock
        /// Retain this class until Apple Pay completes
        var selfRetainer: ApplePayContextClosureDelegate?
        let clientSecret: String

        init(clientSecret: String, completion: @escaping PaymentSheetResultCompletionBlock) {
            self.completion = completion
            self.clientSecret = clientSecret
            super.init()
            self.selfRetainer = self
        }

        func applePayContext(_ context: STPApplePayContext,
                             didCreatePaymentMethod paymentMethod: STPPaymentMethod,
                             paymentInformation: PKPayment,
                             completion: @escaping STPIntentClientSecretCompletionBlock) {
            completion(clientSecret, nil)
        }

        func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Error?) {
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
    }
    
    static func create(
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        completion: @escaping PaymentSheetResultCompletionBlock
    ) -> STPApplePayContext? {
        guard let applePay = configuration.applePay else {
            return nil
        }
        let paymentRequest: PKPaymentRequest
        switch intent {
        case .paymentIntent(let paymentIntent):
            paymentRequest = StripeAPI.paymentRequest(
                withMerchantIdentifier: applePay.merchantId,
                country: applePay.merchantCountryCode,
                currency: paymentIntent.currency
            )
            if let paymentSummaryItems = applePay.paymentSummaryItems {
                // Use the merchant supplied paymentSummaryItems
                paymentRequest.paymentSummaryItems = paymentSummaryItems
            } else {
                // Automatically configure paymentSummaryItems
                let decimalAmount = NSDecimalNumber.stp_decimalNumber(withAmount: paymentIntent.amount, currency: paymentIntent.currency)
                paymentRequest.paymentSummaryItems = [
                    PKPaymentSummaryItem(label: configuration.merchantDisplayName, amount: decimalAmount, type: .final),
                ]
            }
        case .setupIntent:
            paymentRequest = StripeAPI.paymentRequest(
                withMerchantIdentifier: applePay.merchantId,
                country: applePay.merchantCountryCode,
                currency: "USD" // currency is required but unused
            )
            if let paymentSummaryItems = applePay.paymentSummaryItems {
                // Use the merchant supplied paymentSummaryItems
                paymentRequest.paymentSummaryItems = paymentSummaryItems
            } else {
                // Automatically configure paymentSummaryItems.
                paymentRequest.paymentSummaryItems = [
                    PKPaymentSummaryItem(label: "\(configuration.merchantDisplayName)", amount: .one, type: .pending)
                ]
            }
        }
        let delegate = ApplePayContextClosureDelegate(clientSecret: intent.clientSecret, completion: completion)
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
