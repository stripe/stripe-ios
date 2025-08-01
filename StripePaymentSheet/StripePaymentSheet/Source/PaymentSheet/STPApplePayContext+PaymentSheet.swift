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

typealias PaymentSheetResultCompletionBlock = ((PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void)

/// A shim class; ApplePayContext expects a protocol/delegate, but PaymentSheet uses closures.
private class ApplePayContextClosureDelegate: NSObject, ApplePayContextDelegate {
    let completion: PaymentSheetResultCompletionBlock
    /// Retain this class until Apple Pay completes
    var selfRetainer: ApplePayContextClosureDelegate?
    let authorizationResultHandler:
    ((PKPaymentAuthorizationResult, @escaping ((PKPaymentAuthorizationResult) -> Void)) -> Void)?
    let shippingMethodUpdateHandler:
    ((PKShippingMethod, @escaping ((PKPaymentRequestShippingMethodUpdate) -> Void)) -> Void)?
    let shippingContactUpdateHandler:
    ((PKContact, @escaping ((PKPaymentRequestShippingContactUpdate) -> Void)) -> Void)?

    let intent: Intent

    init(
        intent: Intent,
        authorizationResultHandler: (
            (PKPaymentAuthorizationResult, @escaping ((PKPaymentAuthorizationResult) -> Void)) -> Void
        )?,
        shippingMethodUpdateHandler: (
            (PKShippingMethod, @escaping ((PKPaymentRequestShippingMethodUpdate) -> Void)) -> Void
        )?,
        shippingContactUpdateHandler: (
            (PKContact, @escaping ((PKPaymentRequestShippingContactUpdate) -> Void)) -> Void
        )?,
        completion: @escaping PaymentSheetResultCompletionBlock
    ) {
        self.completion = completion
        self.authorizationResultHandler = authorizationResultHandler
        self.shippingMethodUpdateHandler = shippingMethodUpdateHandler
        self.shippingContactUpdateHandler = shippingContactUpdateHandler
        self.intent = intent
        super.init()
        self.selfRetainer = self
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod,
        paymentInformation: PKPayment,
        completion: @escaping STPIntentClientSecretCompletionBlock
    ) {
        switch intent {
        case .paymentIntent(let paymentIntent):
            completion(paymentIntent.clientSecret, nil)
        case .setupIntent(let setupIntent):
            completion(setupIntent.clientSecret, nil)
        case .deferredIntent(let intentConfig):
            guard let stpPaymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: paymentMethod.allResponseFields) else {
                assertionFailure("Failed to convert StripeAPI.PaymentMethod to STPPaymentMethod!")
                completion(nil, STPApplePayContext.makeUnknownError(message: "Failed to convert StripeAPI.PaymentMethod to STPPaymentMethod."))
                return
            }

            // Check if this is a shared payment token session, which will have a preparePaymentMethodHandler
            if let preparePaymentMethodHandler = intentConfig.preparePaymentMethodHandler {
                // Extract shipping address from the PKPayment
                let shippingAddress = paymentInformation.shippingContact != nil ? STPAddress(pkContact: paymentInformation.shippingContact!) : nil

                // Try to create a radar session for the payment method before calling the handler
                context.apiClient.createSavedPaymentMethodRadarSession(paymentMethodId: stpPaymentMethod.stripeId) { _, error in
                    // If radar session creation fails, just continue with the payment method directly
                    if let error {
                        // Log the error but don't fail the payment
                        let errorAnalytic = ErrorAnalytic(event: .savedPaymentMethodRadarSessionFailure, error: error)
                        STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic, apiClient: context.apiClient)
                    }

                    // Call the handler regardless of radar session success/failure
                    preparePaymentMethodHandler(stpPaymentMethod, shippingAddress)
                    completion(STPApplePayContext.COMPLETE_WITHOUT_CONFIRMING_INTENT, nil)
                }
                return
            }

            // Regular deferred intent flow
            let shouldSavePaymentMethod = false // Apple Pay doesn't present the customer the choice to choose to save their payment method
            intentConfig.confirmHandler(stpPaymentMethod, shouldSavePaymentMethod) { result in
                switch result {
                case .success(let clientSecret):
                    guard clientSecret != PaymentSheet.IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT else {
                        completion(STPApplePayContext.COMPLETE_WITHOUT_CONFIRMING_INTENT, nil)
                        return
                    }
                    completion(clientSecret, nil)
                case .failure(let error):
                    completion(nil, error)
                }
            }
        }
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didCompleteWith status: STPApplePayContext.PaymentStatus,
        error: Error?
    ) {
        let confirmType: STPAnalyticsClient.DeferredIntentConfirmationType? = {
            guard
                let confirmType = context.confirmType,
                case .deferredIntent = intent
            else {
                return nil
            }
            switch confirmType {
            case .server:
                return .server
            case .client:
                return .client
            case .none:
                return .completeWithoutConfirmingIntent
            }
        }()
        switch status {
        case .success:
            completion(.completed, confirmType)
        case .error:
            completion(.failed(error: error!), confirmType)
        case .userCancellation:
            completion(.canceled, confirmType)
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
    func applePayContext(
        _ context: STPApplePayContext,
        didSelect shippingMethod: PKShippingMethod,
        handler: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void) {
            if let shippingMethodUpdateHandler {
                shippingMethodUpdateHandler(shippingMethod) { result in
                    handler(result)
                }
            } else {
                handler(PKPaymentRequestShippingMethodUpdate())
            }
        }

    func applePayContext(
        _ context: STPApplePayContext,
        didSelectShippingContact shippingContact: PKContact,
        handler: @escaping (PKPaymentRequestShippingContactUpdate) -> Void) {
            if let shippingContactUpdateHandler {
                shippingContactUpdateHandler(shippingContact) { result in
                    handler(result)
                }
            } else {
                handler(PKPaymentRequestShippingContactUpdate())
            }
        }
}

extension STPApplePayContext {

    static func create(
        intent: Intent,
        configuration: PaymentElementConfiguration,
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
            intent: intent,
            authorizationResultHandler: configuration.applePay?.customHandlers?.authorizationResultHandler,
            shippingMethodUpdateHandler: configuration.applePay?.customHandlers?.shippingMethodUpdateHandler,
            shippingContactUpdateHandler: configuration.applePay?.customHandlers?.shippingContactUpdateHandler,
            completion: completion
        )
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: delegate) {
            applePayContext.shippingDetails = makeShippingDetails(from: configuration)
            applePayContext.apiClient = configuration.apiClient
            applePayContext.returnUrl = configuration.returnURL
            return applePayContext
        } else {
            // Delegate only deallocs when Apple Pay completes
            // Since Apple Pay failed to start, nil it out now
            delegate.selfRetainer = nil
            return nil
        }
    }

    static func createPaymentRequest(
        intent: Intent,
        configuration: PaymentElementConfiguration,
        applePay: PaymentSheet.ApplePayConfiguration
    ) -> PKPaymentRequest {
        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: applePay.merchantId,
            country: applePay.merchantCountryCode,
            currency: intent.currency ?? "USD"
        )
        paymentRequest.requiredBillingContactFields = makeRequiredBillingDetails(from: configuration)
        paymentRequest.requiredShippingContactFields = makeRequiredShippingDetails(from: configuration)
        if let paymentSummaryItems = applePay.paymentSummaryItems {
            // Use the merchant supplied paymentSummaryItems
            paymentRequest.paymentSummaryItems = paymentSummaryItems
        } else {
            // Automatically configure paymentSummaryItems.
            if let amount = intent.amount {
                let decimalAmount = NSDecimalNumber.stp_decimalNumber(
                    withAmount: amount,
                    currency: intent.currency
                )
                paymentRequest.paymentSummaryItems = [
                    PKPaymentSummaryItem(label: configuration.merchantDisplayName, amount: decimalAmount, type: .final),
                ]
            } else {
                paymentRequest.paymentSummaryItems = [
                    PKPaymentSummaryItem(label: configuration.merchantDisplayName, amount: .zero, type: .pending),
                ]
            }
        }

        if intent.isSetupFutureUsageSet(for: .card) {
            // Disable Apple Pay Later if the merchant is setting up the payment method for future usage
#if compiler(>=5.9)
            if #available(macOS 14.0, iOS 17.0, *) {
                paymentRequest.applePayLaterAvailability = .unavailable(.recurringTransaction)
            }
#endif
        }

        // Update list of `supportedNetworks` based on the merchant's configuration of cardBrandAcceptance
        paymentRequest.supportedNetworks = paymentRequest.supportedNetworks.filter { configuration.cardBrandFilter.isAccepted(cardBrand: $0.asCardBrand) }

        return paymentRequest
    }
}

private func makeShippingDetails(from configuration: PaymentElementConfiguration) -> StripeAPI.ShippingDetails? {
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

private func makeRequiredBillingDetails(from configuration: PaymentElementConfiguration) -> Set<PKContactField> {
    var requiredPKContactFields = Set<PKContactField>()
    let billingConfig = configuration.billingDetailsCollectionConfiguration
    // By default, we always want to request the billing address (as it includes the postal code)
    if billingConfig.address == .automatic || billingConfig.address == .full {
        requiredPKContactFields.insert(.postalAddress)
    }
    // Only request name field - phone and email go into shipping contact fields
    if billingConfig.name == .always {
        requiredPKContactFields.insert(.name)
    }
    return requiredPKContactFields
}

private func makeRequiredShippingDetails(from configuration: PaymentElementConfiguration) -> Set<PKContactField> {
    var requiredPKContactFields = Set<PKContactField>()
    let billingConfig = configuration.billingDetailsCollectionConfiguration
    // Phone and email are collected through shipping contact fields
    if billingConfig.email == .always {
        requiredPKContactFields.insert(.emailAddress)
    }
    if billingConfig.phone == .always {
        requiredPKContactFields.insert(.phoneNumber)
    }
    return requiredPKContactFields
}

extension PKPaymentNetwork {
    var asCardBrand: STPCardBrand {
        switch self {
        case .amex:
            return .amex
        case .cartesBancaires:
            return .cartesBancaires
        case .chinaUnionPay:
            return .unionPay
        case .discover:
            return .discover
        case .masterCard:
            return .mastercard
        case .visa:
            return .visa
        case .JCB:
            return .JCB
        default:
            return .unknown
        }
    }
}
