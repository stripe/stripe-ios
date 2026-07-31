//
//  CheckoutApplePayContext.swift
//  StripePaymentSheet
//

import Foundation
import PassKit
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// A closure-based `ApplePayContextDelegate` for the Checkout confirm flow.
///
/// This delegate is purpose-built for `Checkout.confirm()` and reports results as
/// `Checkout.ConfirmResult`. It is distinct from `ApplePayContextClosureDelegate`, which
/// is used by the Intent-based PaymentSheet path and reports results as `PaymentSheetResult`.
final class CheckoutApplePayContextClosureDelegate: NSObject, ApplePayContextDelegate {

    // MARK: - Properties

    private weak var checkout: Checkout?
    private let completion: (Checkout.ConfirmResult) -> Void
    /// Retains this instance until Apple Pay completes.
    private var selfRetainer: CheckoutApplePayContextClosureDelegate?
    /// The payment status captured from the session after a successful confirmation.
    /// Cached here so it can be safely read in `didCompleteWith`, which is called
    /// from a dispatch-to-main callback in STPApplePayContext.
    private var confirmedPaymentStatus: Checkout.PaymentStatus?

    // MARK: - Init

    init(
        checkout: Checkout,
        completion: @escaping (Checkout.ConfirmResult) -> Void
    ) {
        self.checkout = checkout
        self.completion = completion
        super.init()
        self.selfRetainer = self
    }

    // MARK: - ApplePayContextDelegate

    func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod,
        paymentInformation: PKPayment
    ) async throws -> String {
        guard let checkout else {
            throw PaymentSheetError.unknown(debugDescription: "Checkout instance was deallocated before Apple Pay could complete.")
        }

        let session = checkout.session

        // Build client attribution metadata for the Checkout session path.
        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            intent: .checkout(session),
            elementsSession: session.elementsSession
        )

        let expectedAmount = session.expectedAmount()
        let shipping = CheckoutApplePayShippingHelper.makeShippingDetailsParams(from: paymentInformation)

        let response = try await context.apiClient.confirmCheckoutSession(
            sessionId: session.id,
            paymentMethod: paymentMethod.id,
            expectedAmount: expectedAmount,
            expectedPaymentMethodType: STPPaymentMethodType.card.identifier,
            returnURL: context.returnUrl,
            shipping: shipping,
            paymentMethodOptions: nil,
            clientAttributionMetadata: clientAttributionMetadata
        )

        try await checkout.commitSession(response)
        confirmedPaymentStatus = checkout.session.status?.paymentStatus
        return try response.intentClientSecret()
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didCompleteWith status: STPApplePayContext.PaymentStatus,
        error: Error?
    ) {
        let result: Checkout.ConfirmResult
        switch status {
        case .success:
            result = .succeeded(paymentStatus: confirmedPaymentStatus ?? .unknown)
        case .error:
            result = .failed(error ?? STPApplePayContext.makeUnknownError(message: "Apple Pay completed with an unknown error."))
        case .userCancellation:
            result = .canceled
        }
        completion(result)
        selfRetainer = nil
    }
}

// MARK: - Factory

extension CheckoutApplePayContextClosureDelegate {

    /// Creates a configured `STPApplePayContext` for the Checkout confirm flow, or `nil` if
    /// Apple Pay is not available or is not configured.
    static func makeApplePayContext(
        for checkout: Checkout,
        completion: @escaping (Checkout.ConfirmResult) -> Void
    ) -> STPApplePayContext? {
        guard let applePayConfiguration = checkout.configuration.applePayConfiguration else {
            return nil
        }

        let session = checkout.session
        let label = checkout.effectiveMerchantDisplayName

        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: applePayConfiguration.merchantId,
            country: applePayConfiguration.merchantCountryCode,
            currency: session.currency ?? "USD"
        )
        paymentRequest.paymentSummaryItems = STPApplePayContext.makePaymentSummaryItems(
            for: session,
            label: label,
            currency: session.currency
        )

        let delegate = CheckoutApplePayContextClosureDelegate(
            checkout: checkout,
            completion: completion
        )

        guard let context = STPApplePayContext(paymentRequest: paymentRequest, delegate: delegate) else {
            delegate.selfRetainer = nil
            return nil
        }

        context.apiClient = checkout.apiClient
        context.returnUrl = checkout.configuration.returnURL
        return context
    }
}

// MARK: - Shared shipping utilities

/// Shared Apple Pay shipping helpers used by both the Intent-based and Checkout confirm paths.
enum CheckoutApplePayShippingHelper {

    /// Extracts shipping details from a `PKPayment` for use in a confirm API call.
    ///
    /// Returns `nil` when the payment has no shipping contact, or when the contact's address
    /// is missing a street line (which is required by the API).
    static func makeShippingDetailsParams(from payment: PKPayment) -> STPPaymentIntentShippingDetailsParams? {
        guard let shippingContact = payment.shippingContact,
              let nameComponents = shippingContact.name else {
            return nil
        }

        let name = PersonNameComponentsFormatter.localizedString(from: nameComponents, style: .default)
        let shippingAddress = STPAddress(pkContact: shippingContact)

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
}
