//
//  Checkout+ApplePay.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 8/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Contacts
import Foundation
import PassKit
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

// MARK: - ApplePayPaymentState

enum ApplePayPaymentState {
    case notStarted
    case pending    // confirm is in flight — cannot cancel
    case success
    case error
}

// MARK: - CheckoutApplePayContext

/// Manages an active Apple Pay session. Non-nil on `Checkout` only while the sheet is presented.
/// Owns the `PKPaymentAuthorizationController` and acts as its delegate directly.
@MainActor
final class CheckoutApplePayContext: NSObject, PKPaymentAuthorizationControllerDelegate {
    private weak var checkout: Checkout?
    let apiClient: STPAPIClient
    let paymentHandler: STPPaymentHandler
    let controller: PKPaymentAuthorizationController
    var continuation: CheckedContinuation<Checkout.InternalConfirmResult, Never>?
    var result: Checkout.InternalConfirmResult?
    var paymentState: ApplePayPaymentState = .notStarted
    /// Set when Apple Pay times out or the user cancels while a confirm call is in flight.
    /// Dismissal is deferred until the in-flight confirm finishes.
    var didCancelOrTimeoutWhilePending = false
    let session: Checkout.Session
    let merchantLabel: String
    let clientAttributionMetadata: STPClientAttributionMetadata
    let fallbackBillingDetails: StripeAPI.BillingDetails?
    let returnURL: String?
    let authenticationContext: STPAuthenticationContext
    /// Captured at init time so `responds(to:)` can be called nonisolated.
    private let shouldUpdateBillingTaxRegion: Bool
    private let shouldUpdateShipping: Bool

    init(
        checkout: Checkout,
        apiClient: STPAPIClient,
        paymentHandler: STPPaymentHandler,
        controller: PKPaymentAuthorizationController,
        merchantLabel: String,
        clientAttributionMetadata: STPClientAttributionMetadata,
        fallbackBillingDetails: StripeAPI.BillingDetails?,
        returnURL: String?,
        authenticationContext: STPAuthenticationContext
    ) {
        self.checkout = checkout
        self.session = checkout.session
        self.apiClient = apiClient
        self.paymentHandler = paymentHandler
        self.controller = controller
        self.merchantLabel = merchantLabel
        self.clientAttributionMetadata = clientAttributionMetadata
        self.fallbackBillingDetails = fallbackBillingDetails
        self.returnURL = returnURL
        self.authenticationContext = authenticationContext
        self.shouldUpdateBillingTaxRegion = checkout.session.shouldSendTaxRegion(for: "billing")
        self.shouldUpdateShipping = checkout.session.requiresShippingAddress
            || checkout.session.shouldSendTaxRegion(for: "shipping")
        super.init()
    }

    // MARK: - PKPaymentAuthorizationControllerDelegate

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        Task { @MainActor in
            do {
                // 1. Create PaymentMethod (PaymentState still .notStarted here — failure is recoverable)
                let paymentMethodId = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                    StripeAPI.PaymentMethod.create(
                        apiClient: self.apiClient,
                        payment: payment,
                        fallbackBillingDetails: self.fallbackBillingDetails,
                        clientAttributionMetadata: self.clientAttributionMetadata
                    ) { result in
                        continuation.resume(with: result.map { $0.id })
                    }
                }

                // 2. Confirm — set .pending first, cannot cancel after this
                self.paymentState = .pending
                let response = try await self.apiClient.confirmCheckoutSession(
                    sessionId: self.session.id,
                    paymentMethod: paymentMethodId,
                    expectedAmount: self.session.expectedAmount(),
                    expectedPaymentMethodType: STPPaymentMethodType.card.identifier,
                    returnURL: self.returnURL,
                    shipping: self.makeShippingDetailsParams(from: payment),
                    clientAttributionMetadata: self.clientAttributionMetadata
                )

                // 3. Handle next actions
                let paymentSheetResult = try await self.handleConfirmResponse(response)
                self.paymentState = .success
                self.result = .init(
                    paymentSheetResult: paymentSheetResult,
                    checkoutSessionResponse: response
                )

                if self.didCancelOrTimeoutWhilePending {
                    self.finishAndDismiss()
                } else {
                    completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                }
            } catch {
                self.paymentState = .error
                self.result = .init(paymentSheetResult: .failed(error: error))
                let pkError = STPAPIClient.pkPaymentError(forStripeError: error)
                if self.didCancelOrTimeoutWhilePending {
                    self.finishAndDismiss()
                } else {
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: [pkError].compactMap { $0 }))
                }
            }
        }
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        Task { @MainActor in
            switch self.paymentState {
            case .notStarted:
                await controller.dismiss()
                self.resume(with: .init(paymentSheetResult: .canceled))
            case .pending:
                // A confirm call is in flight — defer dismissal until it completes.
                self.didCancelOrTimeoutWhilePending = true
            case .success, .error:
                await controller.dismiss()
                self.resume(with: self.result ?? .init(paymentSheetResult: .canceled))
            }
        }
    }

    nonisolated func presentationWindow(for controller: PKPaymentAuthorizationController) -> UIWindow? {
        return nil
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        handler: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let postalAddress = paymentMethod.billingAddress?.postalAddresses.first?.value,
               let address = Self.makeCheckoutAddress(from: postalAddress) {
                do {
                    try await self.checkout?.updateBillingTaxRegionIfNecessary(
                        address: address,
                        canUpdateWhileSheetPresented: true
                    )
                } catch {
                    // Best effort — return current session state on failure.
                }
            }
            handler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: self.summaryItems()))
        }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact,
        handler: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let postalAddress = contact.postalAddress,
               let address = Self.makeCheckoutAddress(from: postalAddress) {
                do {
                    // TODO: Validate address.country against session.allowedShippingCountries.
                    try await self.checkout?.updateShippingTaxRegionIfNecessary(
                        address: address,
                        canUpdateWhileSheetPresented: true
                    )
                } catch {
                    // Best effort — return current session state on failure.
                }
            }
            handler(PKPaymentRequestShippingContactUpdate(paymentSummaryItems: self.summaryItems()))
        }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didChangeCouponCode couponCode: String,
        handler: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    ) {
        // TODO: Wire up coupon code handling.
        Task { @MainActor [weak self] in
            guard let self else { return }
            handler(PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: self.summaryItems()))
        }
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(paymentAuthorizationController(_:didSelectPaymentMethod:handler:)) {
            return shouldUpdateBillingTaxRegion
        }
        if aSelector == #selector(paymentAuthorizationController(_:didSelectShippingContact:handler:)) {
            return shouldUpdateShipping
        }
        if aSelector == #selector(paymentAuthorizationController(_:didChangeCouponCode:handler:)) {
            return false
        }
        return super.responds(to: aSelector)
    }

    // MARK: - Factory

    static func create(
        checkout: Checkout,
        authenticationContext: STPAuthenticationContext
    ) -> CheckoutApplePayContext? {
        guard let applePayConfig = checkout.configuration.applePayConfiguration else {
            return nil
        }

        let checkoutSession = checkout.session
        let countryCode = checkoutSession.elementsSession.merchantCountryCode ?? "US"
        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: applePayConfig.merchantId,
            country: countryCode,
            currency: checkoutSession.currency ?? "USD"
        )

        let merchantLabel = checkoutSession.businessName ?? checkout.configuration.merchantDisplayName ?? ""
        paymentRequest.paymentSummaryItems = CheckoutApplePayContext.makePaymentSummaryItems(
            for: checkoutSession,
            label: merchantLabel,
            currency: checkoutSession.currency
        )
        if checkoutSession.requiresShippingAddress {
            paymentRequest.requiredShippingContactFields.formUnion([.postalAddress, .name])
        }

        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
            intent: .checkout(checkoutSession),
            elementsSession: checkoutSession.elementsSession
        )

        var fallbackBillingDetails: StripeAPI.BillingDetails?
        if let email = checkoutSession.email {
            var details = StripeAPI.BillingDetails()
            details.email = email
            fallbackBillingDetails = details
        }

        let controller = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        return CheckoutApplePayContext(
            checkout: checkout,
            apiClient: checkout.apiClient,
            paymentHandler: checkout.paymentHandler,
            controller: controller,
            merchantLabel: merchantLabel,
            clientAttributionMetadata: clientAttributionMetadata,
            fallbackBillingDetails: fallbackBillingDetails,
            returnURL: checkout.configuration.returnURL,
            authenticationContext: authenticationContext
        )
    }

    // MARK: - Present

    func presentApplePay() async -> Checkout.InternalConfirmResult {
        controller.delegate = self
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            controller.present()
        }
    }

    // MARK: - Private Helpers

    private func summaryItems() -> [PKPaymentSummaryItem] {
        guard let session = checkout?.session else { return [] }
        return Self.makePaymentSummaryItems(for: session, label: merchantLabel, currency: session.currency)
    }

    private func resume(with result: Checkout.InternalConfirmResult) {
        continuation?.resume(returning: result)
        checkout?.applePayContext = nil
    }

    /// Called when Apple Pay timed out or was canceled while a confirm was in flight.
    /// The completion block from `didAuthorizePayment` is not called — instead we dismiss directly.
    private func finishAndDismiss() {
        Task {
            await controller.dismiss()
            resume(with: result ?? .init(paymentSheetResult: .canceled))
        }
    }

    private func handleConfirmResponse(_ response: PaymentPagesAPIResponse) async throws -> PaymentSheetResult {
        if let setupIntent = response.setupIntent {
            return await withCheckedContinuation { continuation in
                paymentHandler.handleNextAction(
                    for: setupIntent,
                    with: authenticationContext,
                    returnURL: returnURL
                ) { status, _, error in
                    continuation.resume(returning: PaymentSheet.makePaymentSheetResult(for: status, error: error))
                }
            }
        } else if let paymentIntent = response.paymentIntent {
            return await withCheckedContinuation { continuation in
                paymentHandler.handleNextAction(
                    for: paymentIntent,
                    with: authenticationContext,
                    returnURL: returnURL
                ) { status, _, error in
                    continuation.resume(returning: PaymentSheet.makePaymentSheetResult(for: status, error: error))
                }
            }
        } else {
            throw PaymentSheetError.unknown(
                debugDescription: "Checkout session confirm response contained neither a PaymentIntent nor a SetupIntent"
            )
        }
    }

    // MARK: - Static Helpers

    /// Builds Apple Pay summary items from a checkout session's current state.
    /// Falls back to a single total row (or .pending) when line items aren't available.
    static func makePaymentSummaryItems(
        for session: Checkout.Session,
        label: String,
        currency: String?
    ) -> [PKPaymentSummaryItem] {
        guard !session.lineItems.isEmpty, let total = session.total else {
            if let amount = session.expectedAmount() {
                let decimalAmount = NSDecimalNumber.stp_decimalNumber(withAmount: amount, currency: currency)
                return [PKPaymentSummaryItem(label: label, amount: decimalAmount, type: .final)]
            } else {
                return [PKPaymentSummaryItem(label: label, amount: .zero, type: .pending)]
            }
        }

        var summaryItems: [PKPaymentSummaryItem] = []

        for lineItem in session.lineItems {
            let itemLabel = lineItem.quantity > 1
                ? String.Localized.lineItemLabel(name: lineItem.name, quantity: lineItem.quantity)
                : lineItem.name
            let unitMinorUnits = lineItem.unitAmount?.minorUnitsAmount ?? 0
            let amount = NSDecimalNumber.stp_decimalNumber(
                withAmount: unitMinorUnits * lineItem.quantity,
                currency: currency
            )
            summaryItems.append(PKPaymentSummaryItem(label: itemLabel, amount: amount, type: .final))
        }

        let shipping = total.shippingRate.minorUnitsAmount
        let tax = total.taxExclusive.minorUnitsAmount
        let discount = total.discount.minorUnitsAmount

        // Skip the breakdown rows when there's nothing to break down — line items already sum to the total.
        let hasModifiers = shipping != 0 || tax != 0 || discount != 0
        if hasModifiers {
            summaryItems.append(
                PKPaymentSummaryItem(
                    label: String.Localized.subtotal,
                    amount: NSDecimalNumber.stp_decimalNumber(
                        withAmount: total.subtotal.minorUnitsAmount,
                        currency: currency
                    ),
                    type: .final
                )
            )
            if shipping != 0 {
                summaryItems.append(
                    PKPaymentSummaryItem(
                        label: String.Localized.shipping,
                        amount: NSDecimalNumber.stp_decimalNumber(withAmount: shipping, currency: currency),
                        type: .final
                    )
                )
            }
            if tax != 0 {
                summaryItems.append(
                    PKPaymentSummaryItem(
                        label: String.Localized.tax,
                        amount: NSDecimalNumber.stp_decimalNumber(withAmount: tax, currency: currency),
                        type: .final
                    )
                )
            }
            if discount != 0 {
                // `discount` is non-negative; flip the sign so Apple Pay shows it as a deduction.
                let amount = NSDecimalNumber.stp_decimalNumber(withAmount: discount, currency: currency)
                let negativeAmount = NSDecimalNumber(decimal: -amount.decimalValue)
                summaryItems.append(
                    PKPaymentSummaryItem(
                        label: String.Localized.discount,
                        amount: negativeAmount,
                        type: .final
                    )
                )
            }
        }

        // Apple Pay convention: the last item is the grand total.
        summaryItems.append(
            PKPaymentSummaryItem(
                label: label,
                amount: NSDecimalNumber.stp_decimalNumber(
                    withAmount: total.total.minorUnitsAmount,
                    currency: currency
                ),
                type: .final
            )
        )

        return summaryItems
    }

    // Partial billing address from the Apple Pay sheet (no street until authorization).
    // Returns nil if there's no country to key tax on.
    static func makeCheckoutAddress(from postalAddress: CNPostalAddress) -> Checkout.Address? {
        guard let country = postalAddress.isoCountryCode.nonEmpty else {
            return nil
        }
        return Checkout.Address(
            country: country,
            line1: nil,
            line2: nil,
            city: postalAddress.city.nonEmpty,
            state: postalAddress.state.nonEmpty,
            postalCode: postalAddress.postalCode.nonEmpty
        )
    }

    private func makeShippingDetailsParams(from payment: PKPayment) -> STPPaymentIntentShippingDetailsParams? {
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
