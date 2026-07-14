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
    let authorizationResultHandler: PaymentSheet.ApplePayConfiguration.Handlers.AuthorizationResultHandler?
    let shippingMethodUpdateHandler:
    ((PKShippingMethod, @escaping ((PKPaymentRequestShippingMethodUpdate) -> Void)) -> Void)?
    let shippingContactUpdateHandler:
    ((PKContact, @escaping ((PKPaymentRequestShippingContactUpdate) -> Void)) -> Void)?
    // Recalculates tax from the selected card's billing address. Non-nil only for checkout sessions
    // that source tax from the billing address.
    let paymentMethodUpdateHandler:
    ((PKPaymentMethod, @escaping ((PKPaymentRequestPaymentMethodUpdate) -> Void)) -> Void)?

    let intent: Intent
    let elementsSession: STPElementsSession

    // Billing address captured before presenting the sheet, so we can restore it on cancel (opening the
    // sheet / switching cards mutates it). nil if none was set.
    let billingAddressSnapshot: Checkout.ContactAddress?

    init(
        intent: Intent,
        elementsSession: STPElementsSession,
        authorizationResultHandler: PaymentSheet.ApplePayConfiguration.Handlers.AuthorizationResultHandler?,
        shippingMethodUpdateHandler: (
            (PKShippingMethod, @escaping ((PKPaymentRequestShippingMethodUpdate) -> Void)) -> Void
        )?,
        shippingContactUpdateHandler: (
            (PKContact, @escaping ((PKPaymentRequestShippingContactUpdate) -> Void)) -> Void
        )?,
        paymentMethodUpdateHandler: (
            (PKPaymentMethod, @escaping ((PKPaymentRequestPaymentMethodUpdate) -> Void)) -> Void
        )? = nil,
        billingAddressSnapshot: Checkout.ContactAddress? = nil,
        completion: @escaping PaymentSheetResultCompletionBlock
    ) {
        self.completion = completion
        self.authorizationResultHandler = authorizationResultHandler
        self.shippingMethodUpdateHandler = shippingMethodUpdateHandler
        self.shippingContactUpdateHandler = shippingContactUpdateHandler
        self.paymentMethodUpdateHandler = paymentMethodUpdateHandler
        self.billingAddressSnapshot = billingAddressSnapshot
        self.intent = intent
        self.elementsSession = elementsSession
        super.init()
        self.selfRetainer = self
    }

    // didSelectPaymentMethod fires on *every* Apple Pay payment (including sheet open), unlike the shipping
    // callbacks. Only advertise the selector when we have a handler, so unrelated flows are unaffected.
    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(_stpinternal_STPApplePayContextDelegateBase.applePayContext(_:didSelectPaymentMethod:handler:)) {
            return paymentMethodUpdateHandler != nil
        }
        return super.responds(to: aSelector)
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod,
        paymentInformation: PKPayment
    ) async throws -> String {
        switch intent {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.clientSecret
        case .setupIntent(let setupIntent):
            return setupIntent.clientSecret
        case .checkout(let checkout):
            return try await handleCheckoutSessionApplePay(
                checkout: checkout,
                paymentMethod: paymentMethod,
                paymentInformation: paymentInformation,
                context: context
            )
        case .deferredIntent(let intentConfig):
            guard let stpPaymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: paymentMethod.allResponseFields) else {
                assertionFailure("Failed to convert StripeAPI.PaymentMethod to STPPaymentMethod!")
                throw STPApplePayContext.makeUnknownError(message: "Failed to convert StripeAPI.PaymentMethod to STPPaymentMethod.")
            }

            // Check if this is a shared payment token session, which will have a preparePaymentMethodHandler
            if let preparePaymentMethodHandler = intentConfig.preparePaymentMethodHandler {
                // Extract shipping address from the PKPayment
                let shippingAddress = paymentInformation.shippingContact != nil ? STPAddress(pkContact: paymentInformation.shippingContact!) : nil

                // Try to create a radar session for the payment method before calling the handler
                return try await withCheckedThrowingContinuation { continuation in
                    context.apiClient.createSavedPaymentMethodRadarSession(paymentMethodId: stpPaymentMethod.stripeId) { _, error in
                        // If radar session creation fails, just continue with the payment method directly
                        if let error {
                            // Log the error but don't fail the payment
                            let errorAnalytic = ErrorAnalytic(event: .savedPaymentMethodRadarSessionFailure, error: error)
                            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic, apiClient: context.apiClient)
                        }

                        // Call the handler regardless of radar session success/failure
                        preparePaymentMethodHandler(stpPaymentMethod, shippingAddress)
                        continuation.resume(returning: STPApplePayContext.COMPLETE_WITHOUT_CONFIRMING_INTENT)
                    }
                }
            }

            // Route to confirmation token flow or payment method flow based on available handlers
            if let confirmationTokenConfirmHandler = intentConfig.confirmationTokenConfirmHandler {
                // Confirmation token flow
                return try await handleConfirmationTokenFlow(
                    intentConfig: intentConfig,
                    paymentMethod: stpPaymentMethod,
                    paymentInformation: paymentInformation,
                    context: context,
                    confirmationTokenConfirmHandler: confirmationTokenConfirmHandler
                )
            } else if let confirmHandler = intentConfig.confirmHandler {
                // PaymentMethod-based deferred intent flow
                let shouldSavePaymentMethod = false // Apple Pay doesn't present the customer the choice to choose to save their payment method
                let clientSecret = try await confirmHandler(stpPaymentMethod, shouldSavePaymentMethod)
                guard clientSecret != PaymentSheet.IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT else {
                    return STPApplePayContext.COMPLETE_WITHOUT_CONFIRMING_INTENT
                }
                return clientSecret
            } else {
                // Neither handler is available
                throw PaymentSheetError.integrationError(nonPIIDebugDescription: "No confirm handler available in IntentConfiguration")
            }
        }
    }

    private func handleConfirmationTokenFlow(
        intentConfig: PaymentSheet.IntentConfiguration,
        paymentMethod: STPPaymentMethod,
        paymentInformation: PKPayment,
        context: STPApplePayContext,
        confirmationTokenConfirmHandler: @escaping PaymentSheet.IntentConfiguration.ConfirmationTokenConfirmHandler
    ) async throws -> String {
        // Create confirmation token params
        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.paymentMethod = paymentMethod.stripeId
        confirmationTokenParams.returnURL = context.returnUrl
        confirmationTokenParams.clientAttributionMetadata = context.clientAttributionMetadata
        // Only send clientContext in DEBUG to validate client IntentConfiguration matches server intent.
        // This helps catch integration errors during development (e.g. mismatched currency/amount/SFU)
        // without breaking production payments if server intent changes after client configuration.
        #if DEBUG
        confirmationTokenParams.clientContext = intentConfig.createClientContext(customerId: paymentMethod.customerId)
        #endif
        switch intentConfig.mode {
        case .payment(_, _, let setupFutureUsage, _, _):
            if let sfu = setupFutureUsage?.paymentIntentParamsValue {
                confirmationTokenParams.setupFutureUsage = sfu
            }
        case .setup(_, let setupFutureUsage):
            confirmationTokenParams.setupFutureUsage = setupFutureUsage.paymentIntentParamsValue
        }

        // Set shipping details if available
        confirmationTokenParams.shipping = makeShippingDetailsParams(from: paymentInformation)

        // Create the confirmation token
        let confirmationToken = try await context.apiClient.createConfirmationToken(
            with: confirmationTokenParams,
            ephemeralKeySecret: nil,
            additionalPaymentUserAgentValues: PaymentSheet.makeDeferredPaymentUserAgentValue(intentConfiguration: intentConfig)
        )

        // Call the confirmation token handler
        let clientSecret = try await confirmationTokenConfirmHandler(confirmationToken)

        // Handle case where payment is processed off Stripe
        guard clientSecret != PaymentSheet.IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT else {
            return STPApplePayContext.COMPLETE_WITHOUT_CONFIRMING_INTENT
        }
        return clientSecret
    }

    // TODO(gbirch): Remove session parameter once MPE is MainActor-isolated; we can then
    // access checkout.session directly. This is a temporary stopgap to provide a threadsafe
    // version of the checkout session data.
    /// Handles Apple Pay confirmation for CheckoutSession by calling the confirm API with the payment method.
    private func handleCheckoutSessionApplePay(
        checkout: Checkout,
        paymentMethod: StripeAPI.PaymentMethod,
        paymentInformation: PKPayment,
        context: STPApplePayContext
    ) async throws -> String {
        // Sync the full billing address (incl. line1, now available post-authorization) so the server computes
        // the final tax. This also drains any in-flight sheet-open tax update, so expectedAmount below reflects
        // the latest tax rather than a stale, pre-tax value.
        if let stpPaymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: paymentMethod.allResponseFields) {
            try await checkout.syncBillingAddress(from: stpPaymentMethod.billingDetails)
        }

        // Re-read after the sync so the values below reflect the latest tax.
        let checkoutSession: Checkout.Session = checkout.nonisolatedSession

        // 1. Build client attribution metadata
        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            intent: intent,
            elementsSession: elementsSession
        )

        // 2. Get expected amount from checkout session
        let expectedAmount = checkoutSession.expectedAmount()

        // 3. Extract shipping details from PKPayment (if provided)
        let shipping = makeShippingDetailsParams(from: paymentInformation)

        // 4. Call confirm API with the Apple Pay payment method
        let response = try await context.apiClient.confirmCheckoutSession(
            sessionId: checkoutSession.id,
            paymentMethod: paymentMethod.id,
            expectedAmount: expectedAmount,
            expectedPaymentMethodType: STPPaymentMethodType.card.identifier,
            returnURL: context.returnUrl,
            shipping: shipping,
            paymentMethodOptions: nil,
            clientAttributionMetadata: clientAttributionMetadata
        )

        // 5. Update the Checkout instance with the confirmed session response
        try await checkout.commitSession(response)

        // 6. Return client secret based on checkout session mode
        return try response.intentClientSecret()
    }

    /// Extracts shipping details from a PKPayment for CheckoutSession confirmation.
    private func makeShippingDetailsParams(from payment: PKPayment) -> STPPaymentIntentShippingDetailsParams? {
        guard let shippingContact = payment.shippingContact,
              let nameComponents = shippingContact.name else {
            return nil
        }

        let name = PersonNameComponentsFormatter.localizedString(from: nameComponents, style: .default)
        let shippingAddress = STPAddress(pkContact: shippingContact)

        // Only create shipping params if we have a valid address line1
        guard let line1 = shippingAddress.line1 else {
            return nil
        }

        let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: line1)
        addressParams.line2 = shippingAddress.line2
        addressParams.city = shippingAddress.city
        addressParams.state = shippingAddress.state
        addressParams.postalCode = shippingAddress.postalCode
        addressParams.country = shippingAddress.country

        let shippingDetailsParams = STPPaymentIntentShippingDetailsParams(address: addressParams, name: name)
        shippingDetailsParams.phone = shippingAddress.phone

        return shippingDetailsParams
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
            restoreBillingAddressAfterCancel()
            completion(.canceled, confirmType)
        }
        selfRetainer = nil
    }

    // On cancel, undo the billing-address mutation from opening the sheet / switching cards (which
    // recalculated tax from a card the user abandoned).
    private func restoreBillingAddressAfterCancel() {
        guard case .checkout(let checkout) = intent else {
            return
        }
        let snapshot = billingAddressSnapshot
        Task { @MainActor in
            guard let snapshot else {
                // No billing address before Apple Pay, and the server can't fully clear a tax region (finest
                // reset is country-only), so we can't perfectly undo. Leave the last-computed value — a
                // documented limitation (MOBILESDK-4638).
                return
            }
            do {
                // No-ops if the address never changed.
                try await checkout.updateBillingAddress(
                    name: snapshot.name,
                    phone: snapshot.phone,
                    address: snapshot.address,
                    canUpdateWhileSheetPresented: true
                )
            } catch {
                // payment's already cancelled, nothing to do if restore fails
            }
        }
    }

    func applePayContext(
        _ context: STPApplePayContext,
        willCompleteWithResult authorizationResult: PKPaymentAuthorizationResult
    ) async -> PKPaymentAuthorizationResult {
        if let authorizationResultHandler {
            return await authorizationResultHandler(authorizationResult)
        } else {
            return authorizationResult
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

    func applePayContext(
        _ context: STPApplePayContext,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        handler: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) {
            if let paymentMethodUpdateHandler {
                paymentMethodUpdateHandler(paymentMethod) { result in
                    handler(result)
                }
            } else {
                handler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []))
            }
        }
}

extension STPApplePayContext {

    static func create(
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        clientAttributionMetadata: STPClientAttributionMetadata,
        completion: @escaping PaymentSheetResultCompletionBlock
    ) -> STPApplePayContext? {
        guard let applePay = configuration.applePay else {
            return nil
        }

        let cardFundingFilter = configuration.cardFundingFilter(for: elementsSession)
        var paymentRequest = createPaymentRequest(intent: intent,
                                                  configuration: configuration,
                                                  applePay: applePay,
                                                  cardFundingFilter: cardFundingFilter)

        if let paymentRequestHandler = configuration.applePay?.customHandlers?.paymentRequestHandler {
            paymentRequest = paymentRequestHandler(paymentRequest)
        }

        // For checkout sessions that source tax from the billing address, keep the session's billing address
        // (and displayed tax) in sync with the sheet as the user opens it / switches cards. Snapshot the
        // current address first so we can restore it on cancel.
        var paymentMethodUpdateHandler: ((PKPaymentMethod, @escaping ((PKPaymentRequestPaymentMethodUpdate) -> Void)) -> Void)?
        var billingAddressSnapshot: Checkout.ContactAddress?
        if case .checkout(let checkout) = intent {
            billingAddressSnapshot = checkout.nonisolatedSession.billingAddress
            let label = intent.sellerDetails?.businessName ?? configuration.merchantDisplayName
            let currency = intent.currency
            paymentMethodUpdateHandler = { pkPaymentMethod, completion in
                Task { @MainActor in
                    if let postalAddress = pkPaymentMethod.billingAddress?.postalAddresses.first?.value,
                       let address = STPApplePayContext.makeCheckoutAddress(from: postalAddress) {
                        // on failure, fall through with the current (unchanged) items
                        try? await checkout.updateBillingAddress(address: address, canUpdateWhileSheetPresented: true)
                    }
                    // recompute from the (maybe updated) session: new tax on success, current total otherwise,
                    // never an empty item list
                    let items = STPApplePayContext.makePaymentSummaryItems(for: checkout,
                        label: label,
                        currency: currency
                    )
                    completion(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: items))
                }
            }
        }

        let delegate = ApplePayContextClosureDelegate(
            intent: intent,
            elementsSession: elementsSession,
            authorizationResultHandler: configuration.applePay?.customHandlers?.authorizationResultHandler,
            shippingMethodUpdateHandler: configuration.applePay?.customHandlers?.shippingMethodUpdateHandler,
            shippingContactUpdateHandler: configuration.applePay?.customHandlers?.shippingContactUpdateHandler,
            paymentMethodUpdateHandler: paymentMethodUpdateHandler,
            billingAddressSnapshot: billingAddressSnapshot,
            completion: completion
        )
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: delegate) {
            applePayContext.shippingDetails = makeShippingDetails(from: configuration)
            applePayContext.apiClient = configuration.apiClient
            applePayContext.returnUrl = configuration.returnURL
            applePayContext.clientAttributionMetadata = clientAttributionMetadata
            applePayContext.fallbackBillingDetails = makeFallbackBillingDetails(intent: intent, configuration: configuration)
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
        applePay: PaymentSheet.ApplePayConfiguration,
        cardFundingFilter: CardFundingFilter = .default
    ) -> PKPaymentRequest {
        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: applePay.merchantId,
            country: applePay.merchantCountryCode,
            currency: intent.currency ?? "USD"
        )
        paymentRequest.requiredBillingContactFields = makeRequiredBillingDetails(from: configuration)
        paymentRequest.requiredShippingContactFields = makeRequiredShippingDetails(from: configuration)

        let label = intent.sellerDetails?.businessName ?? configuration.merchantDisplayName

        if let paymentSummaryItems = applePay.paymentSummaryItems {
            // Use the merchant supplied paymentSummaryItems
            paymentRequest.paymentSummaryItems = paymentSummaryItems
        } else if case .checkout(let checkout) = intent {
            // same helper used to refresh the sheet post-tax-recalc, so initial and updated lists match
            paymentRequest.paymentSummaryItems = STPApplePayContext.makePaymentSummaryItems(for: checkout,
                label: label,
                currency: intent.currency
            )
        } else {
            // Automatically configure paymentSummaryItems.
            if let amount = intent.amount {
                let decimalAmount = NSDecimalNumber.stp_decimalNumber(
                    withAmount: amount,
                    currency: intent.currency
                )
                paymentRequest.paymentSummaryItems = [
                    PKPaymentSummaryItem(label: label, amount: decimalAmount, type: .final),
                ]
            } else {
                paymentRequest.paymentSummaryItems = [
                    PKPaymentSummaryItem(label: label, amount: .zero, type: .pending),
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

        // Update merchantCapabilities based on the merchant's configuration of allowedCardFundingTypes
        // Only override if a specific funding type filter is configured
        if let merchantCapabilities = cardFundingFilter.applePayMerchantCapabilities() {
            paymentRequest.merchantCapabilities = merchantCapabilities
        }

        // Pre-populate billingContact from the CheckoutSession's billing address if available
        if case .checkout(let checkout) = intent,
           let billingAddress = checkout.nonisolatedSession.billingAddress {
            paymentRequest.billingContact = Self.makeBillingContact(from: billingAddress)
        }

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

private func makeFallbackBillingDetails(
    intent: Intent,
    configuration: PaymentElementConfiguration
) -> StripeAPI.BillingDetails? {
    var fallbackBillingDetails = StripeAPI.BillingDetails()
    var hasFallbackBillingDetails = false

    if case .checkout(let checkout) = intent, let email = checkout.nonisolatedSession.email {
        fallbackBillingDetails.email = email
        hasFallbackBillingDetails = true
    }

    guard configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod else {
        return hasFallbackBillingDetails ? fallbackBillingDetails : nil
    }

    let defaultBillingDetails = configuration.defaultBillingDetails
    if fallbackBillingDetails.email == nil, let email = defaultBillingDetails.email {
        fallbackBillingDetails.email = email
        hasFallbackBillingDetails = true
    }
    if let name = defaultBillingDetails.name {
        fallbackBillingDetails.name = name
        hasFallbackBillingDetails = true
    }
    if let phone = defaultBillingDetails.phone {
        fallbackBillingDetails.phone = phone
        hasFallbackBillingDetails = true
    }
    if defaultBillingDetails.address != .init() {
        let address = defaultBillingDetails.address
        fallbackBillingDetails.address = StripeAPI.BillingDetails.Address(
            city: address.city,
            country: address.country,
            line1: address.line1,
            line2: address.line2,
            postalCode: address.postalCode,
            state: address.state
        )
        hasFallbackBillingDetails = true
    }

    return hasFallbackBillingDetails ? fallbackBillingDetails : nil
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
