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

    let intent: Intent
    let elementsSession: STPElementsSession

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
        completion: @escaping PaymentSheetResultCompletionBlock
    ) {
        self.completion = completion
        self.authorizationResultHandler = authorizationResultHandler
        self.shippingMethodUpdateHandler = shippingMethodUpdateHandler
        self.shippingContactUpdateHandler = shippingContactUpdateHandler
        self.intent = intent
        self.elementsSession = elementsSession
        super.init()
        self.selfRetainer = self
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
        let checkoutSession: Checkout.Session = checkout.nonisolatedSession

        // 0. Update tax region from billing address if the session uses billing address for tax.
        //    Billing contact is only available at authorization time (no mid-sheet callback),
        //    so we apply it here before confirming.
        if checkoutSession.shouldSendTaxRegion(for: "billing"),
           let postalAddress = paymentInformation.billingContact?.postalAddress,
           !postalAddress.isoCountryCode.isEmpty {
            let address = Checkout.Address(
                country: postalAddress.isoCountryCode,
                city: postalAddress.city.isEmpty ? nil : postalAddress.city,
                state: postalAddress.state.isEmpty ? nil : postalAddress.state,
                postalCode: postalAddress.postalCode.isEmpty ? nil : postalAddress.postalCode
            )
            try? await checkout.performUpdate(.setTaxRegion(address))
        }

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
            completion(.canceled, confirmType)
        }
        selfRetainer = nil
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
        handler: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        guard case .checkout(let checkout) = intent else {
            if let shippingMethodUpdateHandler {
                shippingMethodUpdateHandler(shippingMethod) { handler($0) }
            } else {
                handler(PKPaymentRequestShippingMethodUpdate())
            }
            return
        }

        Task { @MainActor in
            if let optionId = shippingMethod.identifier {
                try? await checkout.performUpdate(.setShippingRate(optionId))
            }
            handler(makeShippingMethodUpdate(from: checkout.nonisolatedSession))
        }
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didSelectShippingContact shippingContact: PKContact,
        handler: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        guard case .checkout(let checkout) = intent else {
            if let shippingContactUpdateHandler {
                shippingContactUpdateHandler(shippingContact) { handler($0) }
            } else {
                handler(PKPaymentRequestShippingContactUpdate())
            }
            return
        }

        Task { @MainActor in
            let session = checkout.nonisolatedSession
            // Update tax region with the (redacted) shipping address Apple Pay provides.
            // Apple Pay only shares country, state, and postal code at this stage — enough for tax.
            if session?.shouldSendTaxRegion(for: "shipping") == true,
               let postalAddress = shippingContact.postalAddress,
               !postalAddress.isoCountryCode.isEmpty {
                let address = Checkout.Address(
                    country: postalAddress.isoCountryCode,
                    city: postalAddress.city.isEmpty ? nil : postalAddress.city,
                    state: postalAddress.state.isEmpty ? nil : postalAddress.state,
                    postalCode: postalAddress.postalCode.isEmpty ? nil : postalAddress.postalCode
                )
                try? await checkout.performUpdate(.setTaxRegion(address))
            }
            handler(makeShippingContactUpdate(from: checkout.nonisolatedSession))
        }
    }

    private func makeShippingContactUpdate(from session: Checkout.Session) -> PKPaymentRequestShippingContactUpdate {
        let shippingMethods = session.shippingOptions.map {
            STPApplePayContext.makePKShippingMethod(from: $0, currency: session.currency)
        }
        return PKPaymentRequestShippingContactUpdate(
            errors: [],
            paymentSummaryItems: makeSummaryItems(from: session),
            shippingMethods: shippingMethods
        )
    }

    private func makeShippingMethodUpdate(from session: Checkout.Session) -> PKPaymentRequestShippingMethodUpdate {
        return PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: makeSummaryItems(from: session))
    }

    private func makeSummaryItems(from session: Checkout.Session) -> [PKPaymentSummaryItem] {
        guard !session.lineItems.isEmpty, let total = session.total else { return [] }
        let label = intent.sellerDetails?.businessName ?? ""
        return STPApplePayContext.makeApplePayPaymentSummaryItems(
            lineItems: session.lineItems,
            total: total,
            taxStatus: session.tax.status,
            totalLabel: label,
            currency: session.currency
        )
    }

    @available(iOS 15.0, *)
    func applePayContext(
        _ context: STPApplePayContext,
        didChangeCouponCode couponCode: String
    ) async -> PKPaymentRequestCouponCodeUpdate {
        guard case .checkout(let checkout) = intent else {
            return PKPaymentRequestCouponCodeUpdate(errors: nil, paymentSummaryItems: [], shippingMethods: [])
        }

        do {
            try await checkout.performUpdate(.setPromotionCode(couponCode))
        } catch {
            let couponError = PKPaymentRequest.paymentCouponCodeInvalidError(localizedDescription: error.localizedDescription)
            let session: Checkout.Session = checkout.nonisolatedSession
            return PKPaymentRequestCouponCodeUpdate(
                errors: [couponError],
                paymentSummaryItems: makeSummaryItems(from: session),
                shippingMethods: session.shippingOptions.map { STPApplePayContext.makePKShippingMethod(from: $0, currency: session.currency) }
            )
        }

        let session: Checkout.Session = checkout.nonisolatedSession
        return PKPaymentRequestCouponCodeUpdate(
            errors: nil,
            paymentSummaryItems: makeSummaryItems(from: session),
            shippingMethods: session.shippingOptions.map { STPApplePayContext.makePKShippingMethod(from: $0, currency: session.currency) }
        )
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
        let delegate = ApplePayContextClosureDelegate(
            intent: intent,
            elementsSession: elementsSession,
            authorizationResultHandler: configuration.applePay?.customHandlers?.authorizationResultHandler,
            shippingMethodUpdateHandler: configuration.applePay?.customHandlers?.shippingMethodUpdateHandler,
            shippingContactUpdateHandler: configuration.applePay?.customHandlers?.shippingContactUpdateHandler,
            completion: completion
        )
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: delegate) {
            applePayContext.shippingDetails = makeShippingDetails(from: configuration)
            applePayContext.apiClient = configuration.apiClient
            applePayContext.returnUrl = configuration.returnURL
            applePayContext.clientAttributionMetadata = clientAttributionMetadata
            if case .checkout(let checkout) = intent, let email = checkout.nonisolatedSession.email {
                applePayContext.fallbackBillingDetails = StripeAPI.BillingDetails(email: email)
            }
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
        let checkoutSession: Checkout.Session? = {
            guard case .checkout(let checkout) = intent else { return nil }
            return checkout.nonisolatedSession
        }()
        paymentRequest.requiredBillingContactFields = makeRequiredBillingDetails(from: configuration, checkoutSession: checkoutSession)
        paymentRequest.requiredShippingContactFields = makeRequiredShippingDetails(from: configuration, checkoutSession: checkoutSession)

        let label = intent.sellerDetails?.businessName ?? configuration.merchantDisplayName

        if let paymentSummaryItems = applePay.paymentSummaryItems {
            // Use the merchant supplied paymentSummaryItems
            paymentRequest.paymentSummaryItems = paymentSummaryItems
        } else if case .checkout(let checkout) = intent,
                  !checkout.nonisolatedSession.lineItems.isEmpty,
                  let total = checkout.nonisolatedSession.total {
            paymentRequest.paymentSummaryItems = STPApplePayContext.makeApplePayPaymentSummaryItems(
                lineItems: checkout.nonisolatedSession.lineItems,
                total: total,
                taxStatus: checkout.nonisolatedSession.tax.status,
                totalLabel: label,
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

        // CS: shipping methods, allowed countries, pre-populated shipping contact, and promo code support
        if let checkoutSession {
            if !checkoutSession.shippingOptions.isEmpty {
                paymentRequest.shippingMethods = checkoutSession.shippingOptions.map {
                    Self.makePKShippingMethod(from: $0, currency: checkoutSession.currency)
                }
            }
            if let allowedCountries = checkoutSession.allowedShippingCountries {
                paymentRequest.supportedCountries = Set(allowedCountries)
            }
            if let shippingAddress = checkoutSession.shippingAddress {
                paymentRequest.shippingContact = Self.makeBillingContact(from: shippingAddress)
            }
            if #available(iOS 15.0, *),
               (configuration as? PaymentSheet.Configuration)?.allowsPromotionCodes == true {
                paymentRequest.supportsCouponCode = true
                // Pre-populate if a promo code is already applied to the session
                paymentRequest.couponCode = checkoutSession.discountAmounts.first?.promotionCode
            }
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

private func makeRequiredBillingDetails(from configuration: PaymentElementConfiguration, checkoutSession: Checkout.Session?) -> Set<PKContactField> {
    var requiredPKContactFields = Set<PKContactField>()
    let billingConfig = configuration.billingDetailsCollectionConfiguration

    let shouldRequireBillingAddress: Bool
    if let session = checkoutSession {
        // For CS, require billing address if: address mode is full, phone is collected,
        // or billing address is needed for automatic tax calculation.
        let neededForTax = billingConfig.address != .never && session.shouldSendTaxRegion(for: "billing")
        shouldRequireBillingAddress = billingConfig.address == .full
            || billingConfig.phone == .always
            || neededForTax
    } else {
        shouldRequireBillingAddress = billingConfig.address == .automatic || billingConfig.address == .full
    }

    if shouldRequireBillingAddress {
        requiredPKContactFields.insert(.postalAddress)
    }
    // Only request name field - phone and email go into shipping contact fields
    if billingConfig.name == .always {
        requiredPKContactFields.insert(.name)
    }
    return requiredPKContactFields
}

private func makeRequiredShippingDetails(from configuration: PaymentElementConfiguration, checkoutSession: Checkout.Session?) -> Set<PKContactField> {
    var requiredPKContactFields = Set<PKContactField>()
    let billingConfig = configuration.billingDetailsCollectionConfiguration

    // Collect shipping postal address when the CS has shipping options or needs a shipping
    // address to compute automatic tax.
    if let session = checkoutSession,
       session.requiresShippingAddress || session.shouldSendTaxRegion(for: "shipping") {
        requiredPKContactFields.insert(.postalAddress)
        requiredPKContactFields.insert(.name)
    }

    // Phone and email are collected through shipping contact fields.
    // For CS + .automatic email mode: only require email if the session doesn't already have the customer's email.
    let shouldRequireEmail: Bool
    switch billingConfig.email {
    case .always:
        shouldRequireEmail = true
    case .automatic:
        // For CS, only require email if the session doesn't already have the customer's email.
        // For non-CS intents, .automatic means don't collect.
        shouldRequireEmail = checkoutSession != nil && checkoutSession?.email == nil
    case .never:
        shouldRequireEmail = false
    }

    if shouldRequireEmail {
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
