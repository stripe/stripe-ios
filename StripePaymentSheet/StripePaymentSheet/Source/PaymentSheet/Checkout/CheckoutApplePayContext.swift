//
//  CheckoutApplePayContext.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 8/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Contacts
import Foundation
import PassKit
@_spi(InternalOnlyAPI) import StripeApplePay
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
import UIKit

/// Responsible for handling the Apple Pay flow end to end: displaying line items,
/// collecting billing and shipping, updating tax region, and confirming the Checkout Session.
/// Owns the `PKPaymentAuthorizationController` and acts as its delegate directly.
@MainActor
final class CheckoutApplePayContext: NSObject, PKPaymentAuthorizationControllerDelegate {

    enum PaymentState {
        case notStarted
        case pending
        case error
        case success
    }

    private var session: CheckoutElementsController.Session
    private let merchantLabel: String
    private let apiClient: STPAPIClient
    private let returnURL: String
    private let presentationWindow: UIWindow?
    private let confirmationHandler: CheckoutElementsController.ApplePayConfirmationParameters.ConfirmationHandler
    private let attribution: CheckoutAttributionContext
    private let initialTaxRegion: CheckoutElementsController.Address?
    let authorizationController: PKPaymentAuthorizationController

    private weak var checkoutWalletUpdater: CheckoutSessionWalletUpdater?

    // Internal state
    private var continuation: CheckedContinuation<CheckoutElementsController.InternalConfirmResult, Never>?
    var result: CheckoutElementsController.InternalConfirmResult?
    var paymentState: PaymentState = .notStarted
    /// YES if the flow cancelled or timed out.  This toggles which delegate method (didFinish or didAuthorize) resumes our continuation
    var didCancelOrTimeoutWhilePending = false
    /// Whether or not we fully completed the flow - if didFinish is `true`, that means `_end()` was called and this class is unusable.
    private var didFinish = false
    private var shippingContactUpdateTask: Task<Void, Never>?
    /// The most recent billing tax update, which throws if the update failed.
    /// Apple Pay doesn't display errors returned from a payment method update, so authorization awaits this and handles
    /// the failure instead of letting the customer pay stale totals.
    private var paymentMethodUpdateTask: Task<Void, Error>?

    init(
        checkoutSession: CheckoutElementsController.Session,
        applePayConfirmationParameters: CheckoutElementsController.ApplePayConfirmationParameters,
        authorizationController: PKPaymentAuthorizationController,
        checkoutWalletUpdater: CheckoutSessionWalletUpdater
    ) {
        self.session = checkoutSession
        self.merchantLabel = applePayConfirmationParameters.merchantDisplayName
        self.apiClient = applePayConfirmationParameters.apiClient
        self.returnURL = applePayConfirmationParameters.returnURL
        self.presentationWindow = applePayConfirmationParameters.presentationWindow
        self.confirmationHandler = applePayConfirmationParameters.confirmationHandler
        self.attribution = applePayConfirmationParameters.attribution
        self.initialTaxRegion = checkoutWalletUpdater.currentTaxRegion
        self.authorizationController = authorizationController
        self.checkoutWalletUpdater = checkoutWalletUpdater
        super.init()
    }

    // MARK: - PKPaymentAuthorizationControllerDelegate

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Some observations (on iOS 12 simulator):
        // - The docs say localizedDescription can be shown in the Apple Pay sheet, but I haven't seen this.
        // - If you call the completion block w/ a status of .failure and an error, the user is prompted to try again.

        Task {
            // A billing tax update may still be in flight, or may have failed. Apple Pay doesn't display errors returned from
            // a payment method update, so surface the failure here, where it is shown, and let the customer try again.
            do {
                try await self.paymentMethodUpdateTask?.value
            } catch {
                if let failureResult = await self.retryFailedBillingTaxUpdate(payment: payment) {
                    completion(failureResult)
                    return
                }
            }

            // Helpers to handle annoying logic around "Do I call completion block or dismiss + call delegate?"
            // Helper 1: Handle an unsuccessful result
            let handleUnsuccessfulResult = { (result: CheckoutElementsController.InternalConfirmResult, error: Error?) in
                self.paymentState = .error
                self.result = result
                if self.didCancelOrTimeoutWhilePending {
                    self.finishAndDismiss()
                } else {
                    let pkError = error.flatMap(STPAPIClient.pkPaymentError(forStripeError:))
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: [pkError].compactMap { $0 }))
                }
            }
            // Helper 2: Handle success
            let handleSuccess = { (response: CheckoutClientAPIResponse) in
                self.paymentState = .success
                self.result = .completed(response)
                if self.didCancelOrTimeoutWhilePending {
                    self.finishAndDismiss()
                } else {
                    completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                }
            }

            do {
                // 1. Tokenize the Apple Pay payment
                let checkoutSession = self.session
                let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(
                    checkoutSession: checkoutSession,
                    attribution: attribution
                )
                let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<STPToken, Error>) in
                    self.apiClient.createToken(with: payment) { token, error in
                        if let token {
                            continuation.resume(returning: token)
                        } else {
                            continuation.resume(throwing: error ?? NSError.stp_genericConnectionError())
                        }
                    }
                }
                guard !self.didFinish else {
                    return // The user canceled mid-payment - just abort
                }
                self.paymentState = .pending  // After this point, we can't cancel

                // 2. Confirm
                let cardParams = STPPaymentMethodCardParams()
                cardParams.token = token.tokenId
                let paymentMethodData = STPPaymentMethodParams(
                    card: cardParams,
                    billingDetails: STPAPIClient.billingDetails(from: payment),
                    metadata: nil
                )
                paymentMethodData.clientAttributionMetadata = clientAttributionMetadata
                let requestParameters = CheckoutSessionConfirmationRequestParameters.createWithPaymentMethodData(
                    sessionId: checkoutSession.id,
                    clientSecret: checkoutSession.clientSecret,
                    paymentMethodData: paymentMethodData,
                    confirmationSource: attribution.confirmingElement,
                    expectedAmount: checkoutSession.amount,
                    savePaymentMethod: nil,
                    returnURL: self.returnURL,
                    shipping: self.makeShippingDetailsParams(from: payment)
                        ?? checkoutSession.shippingAddress?.shippingDetailsParams,
                    paymentMethodOptions: nil,
                    clientAttributionMetadata: clientAttributionMetadata,
                    collectedInformation: .init(email: checkoutSession.localState.email),
                    passiveCaptchaToken: nil
                )
                let result = await self.confirmationHandler(requestParameters)
                switch result {
                case .completed(let response):
                    handleSuccess(response)
                case .canceled:
                    handleUnsuccessfulResult(result, nil)
                case .failed(let error, _):
                    handleUnsuccessfulResult(result, error)
                }
            } catch {
                handleUnsuccessfulResult(.failed(error), error)
            }
        }
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        // Note: If you don't dismiss the VC, the UI disappears, the VC blocks interaction, and this method gets called again.
        // Note: This method is called if the user cancels (taps outside the sheet) or Apple Pay times out (empirically ~30 seconds)
        switch paymentState {
        case .notStarted:
            Task {
                await shippingContactUpdateTask?.value
                try? await paymentMethodUpdateTask?.value
                await restoreInitialTaxRegionIfNecessary()
                await controller.dismiss()
                self.resume(with: .canceled())
                self._end()
            }
        case .pending:
            // We can't cancel a pending payment. If we dismiss the VC now, the customer might interact with the app and miss seeing the result of the payment - risking a double charge, chargeback, etc.
            // Instead, we'll dismiss and notify our delegate when the payment finishes.
            didCancelOrTimeoutWhilePending = true
        case .error:
            Task {
                await controller.dismiss()
                self.resume(with: self.result ?? .failed(CheckoutError.unknown(debugDescription: "Apple Pay finished in error state without a result.")))
                self._end()
            }
        case .success:
            Task {
                await controller.dismiss()
                self.resume(with: self.result ?? .canceled())
                self._end()
            }
        }
    }

    @objc nonisolated func presentationWindow(for controller: PKPaymentAuthorizationController) -> UIWindow? {
        return presentationWindow
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        handler: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        guard session.collectsTaxFromBillingAddress,
              let postalAddress = paymentMethod.billingAddress?.postalAddresses.first?.value,
              let address = Self.makeCheckoutAddress(from: postalAddress),
              let checkoutWalletUpdater else {
            // No tax update is needed for this payment method, so there's no failure to report.
            paymentMethodUpdateTask = nil
            handler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: summaryItems()))
            return
        }
        let update = startBillingTaxUpdate(to: address, using: checkoutWalletUpdater)
        Task { @MainActor in
            // A failed update is reported at authorization because Apple Pay ignores errors returned from a payment method update
            _ = await update.result
            handler(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: summaryItems()))
        }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact,
        handler: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        if let allowedCountries = session.allowedShippingCountries,
           let country = contact.postalAddress?.isoCountryCode,
           !allowedCountries.contains(country.uppercased()) {
            let error = CheckoutError.invalidShippingCountry(countryCode: country)
            handler(PKPaymentRequestShippingContactUpdate(
                errors: [error],
                paymentSummaryItems: summaryItems(),
                shippingMethods: []
            ))
            return
        }

        guard session.shouldSendTaxRegion(for: "shipping"),
              let postalAddress = contact.postalAddress,
              let address = Self.makeCheckoutAddress(from: postalAddress),
              let checkoutWalletUpdater else {
            handler(PKPaymentRequestShippingContactUpdate(paymentSummaryItems: summaryItems()))
            return
        }
        shippingContactUpdateTask = Task { @MainActor in
            do {
                try await updateTaxRegion(to: address, using: checkoutWalletUpdater)
                handler(PKPaymentRequestShippingContactUpdate(paymentSummaryItems: summaryItems()))
            } catch {
                // Surface the failure in the Apple Pay sheet. The totals are stale, so the customer must not authorize them.
                // Saving the address again retries the update. This doesn't mark a field, since the failure is rarely the
                // address. Apple Pay ignores a generic PassKit error here, and an unserviceable error says the merchant
                // doesn't ship to the address.
                let shippingError = PKPaymentRequest.paymentContactInvalidError(
                    withContactField: .postalAddress,
                    localizedDescription: NSError.stp_unexpectedErrorMessage()
                )
                handler(PKPaymentRequestShippingContactUpdate(
                    errors: [shippingError],
                    paymentSummaryItems: summaryItems(),
                    shippingMethods: []
                ))
            }
        }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingMethod shippingMethod: PKShippingMethod,
        handler: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        // TODO: Handle multiple shipping rates from the session.
        handler(PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: summaryItems()))
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didChangeCouponCode couponCode: String,
        handler: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    ) {
        // TODO: Wire up coupon code handling.
        handler(PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: summaryItems()))
    }

    // MARK: - Factory

    static func create(
        checkoutSession: CheckoutElementsController.Session,
        applePayConfirmationParameters: CheckoutElementsController.ApplePayConfirmationParameters,
        checkoutWalletUpdater: CheckoutSessionWalletUpdater
    ) throws -> CheckoutApplePayContext {
        guard PKPaymentAuthorizationController.canMakePayments() else {
            let error = CheckoutError.unknown(debugDescription: "Apple Pay is unavailable on this device. Check device support and payment restrictions.")
            STPAnalyticsClient.sharedClient.log(
                analytic: ErrorAnalytic(event: .unexpectedCheckoutElementsError, error: error),
                apiClient: applePayConfirmationParameters.apiClient
            )
            throw error
        }

        // TODO: Product Usage

        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: checkoutSession,
            applePayConfirmationParameters: applePayConfirmationParameters
        )

        // PKPaymentAuthorizationController.init is non-nullable even for invalid requests.
        // Use PKPaymentAuthorizationViewController.init as a proxy — it IS nullable and
        // returns nil when the request can't be presented (e.g. bad merchant ID, unsupported network).
        guard PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) != nil else {
            let error = CheckoutError.unknown(debugDescription: """
                Could not set up Apple Pay. The user cannot make payments on any of the payment request's supported networks.
                """)
            STPAnalyticsClient.sharedClient.log(
                analytic: ErrorAnalytic(event: .unexpectedCheckoutElementsError, error: error),
                apiClient: applePayConfirmationParameters.apiClient
            )
            throw error
        }
        let authorizationController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        return CheckoutApplePayContext(
            checkoutSession: checkoutSession,
            applePayConfirmationParameters: applePayConfirmationParameters,
            authorizationController: authorizationController,
            checkoutWalletUpdater: checkoutWalletUpdater
        )
    }

    // MARK: - Present

    func presentApplePay() async -> CheckoutElementsController.InternalConfirmResult {
        authorizationController.delegate = self
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            authorizationController.present { [weak self] presented in
                guard let self, !presented else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let error = CheckoutError.unknown(debugDescription: """
                        Could not present Apple Pay. Check Apple Pay setup in Wallet and that the merchant ID matches an ID \
                        in the app's Apple Pay entitlements and provisioning profile. Ensure the app is active, \
                        the presenting window is visible, and no other presentation or dismissal is in progress.
                        """)
                    STPAnalyticsClient.sharedClient.log(
                        analytic: ErrorAnalytic(event: .unexpectedCheckoutElementsError, error: error),
                        apiClient: self.apiClient
                    )
                    self.resume(with: .failed(error))
                    self._end()
                }
            }
        }
    }

    // MARK: - Helpers

    // MARK: - Tax updates

    /// Updates the tax region while the Apple Pay sheet is presented.
    private func updateTaxRegion(
        to address: CheckoutElementsController.Address,
        using checkoutWalletUpdater: CheckoutSessionWalletUpdater
    ) async throws {
        session = try await checkoutWalletUpdater.updateTaxRegionWithoutEnqueueing(
            address: address,
            canUpdateWhileSheetPresented: true,
            confirmationSource: attribution.confirmingElement
        )
    }

    /// Starts a billing tax update and tracks it as `paymentMethodUpdateTask`.
    /// Authorization awaits it, and cancelling waits for it before restoring the initial tax region.
    private func startBillingTaxUpdate(
        to address: CheckoutElementsController.Address,
        using checkoutWalletUpdater: CheckoutSessionWalletUpdater
    ) -> Task<Void, Error> {
        let task = Task { @MainActor in
            try await updateTaxRegion(to: address, using: checkoutWalletUpdater)
        }
        paymentMethodUpdateTask = task
        return task
    }

    /// Retries a billing tax update that failed while the Apple Pay sheet was presented, using the billing address Apple Pay
    /// provides at authorization.
    /// - Returns: The authorization result to report, or `nil` if confirmation can continue.
    private func retryFailedBillingTaxUpdate(payment: PKPayment) async -> PKPaymentAuthorizationResult? {
        let displayedAmount = session.amount
        guard let postalAddress = payment.billingContact?.postalAddress,
              let address = Self.makeCheckoutAddress(from: postalAddress),
              let checkoutWalletUpdater else {
            return Self.makeRetryableFailureResult()
        }
        do {
            try await startBillingTaxUpdate(to: address, using: checkoutWalletUpdater).value
        } catch {
            return Self.makeRetryableFailureResult()
        }

        guard session.amount == displayedAmount else {
            // Apple Pay can't update the totals after authorization begins, so close the sheet instead of charging a
            // total the customer didn't see. The session has the new total if they pay again.
            paymentState = .error
            result = .failed(CheckoutError.totalChanged)
            return PKPaymentAuthorizationResult(status: .failure, errors: nil)
        }
        return nil
    }

    /// A failed authorization that keeps the Apple Pay sheet open so the customer can tap Pay again.
    /// Apple Pay closes the sheet for a failure without a PassKit error. This doesn't mark a field, since the failure is
    /// rarely the address.
    private static func makeRetryableFailureResult() -> PKPaymentAuthorizationResult {
        let error = NSError(
            domain: PKPaymentErrorDomain,
            code: PKPaymentError.unknownError.rawValue,
            userInfo: [NSLocalizedDescriptionKey: NSError.stp_unexpectedErrorMessage()]
        )
        return PKPaymentAuthorizationResult(status: .failure, errors: [error])
    }

    private func summaryItems() -> [PKPaymentSummaryItem] {
        return Self.makeSummaryItems(for: session, label: merchantLabel)
    }

    /// Builds Apple Pay summary items from a checkout session's current state.
    /// Returns a pending total row when no payment is required or the total is unavailable.
    static func makeSummaryItems(
        for session: CheckoutElementsController.Session,
        label: String
    ) -> [PKPaymentSummaryItem] {
        let currency = session.activePresentmentCurrency
        guard !session.noPaymentRequired else {
            return [PKPaymentSummaryItem(label: label, amount: .zero, type: .pending)]
        }

        var summaryItems: [PKPaymentSummaryItem] = []

        for orderSummaryItem in session.orderSummaryItems {
            switch orderSummaryItem {
            case .oneTimePrice(let oneTimePrice):
                for item in oneTimePrice.items {
                    let itemLabel = item.quantity > 1
                        ? String.Localized.lineItemLabel(name: item.displayName, quantity: item.quantity)
                        : item.displayName
                    // Prefer unitAmountDecimal for the edge case where the Stripe API doesn't return a `unitAmount`
                    // (and so becomes 0) for prices with sub-cent precision like $0.1234.
                    let unitAmount = item.unitAmountDecimal?.minorUnitsAmount ?? Decimal(item.unitAmount.minorUnitsAmount)
                    let amount = makeApplePayAmount(
                        minorUnitsAmount: unitAmount * Decimal(item.quantity),
                        currency: currency
                    )
                    summaryItems.append(
                        PKPaymentSummaryItem(label: itemLabel, amount: amount, type: .final)
                    )
                }
            }
        }

        let totals = session.totals
        let tax = totals.taxExclusive.minorUnitsAmount
        let discount = totals.discount.minorUnitsAmount

        // Skip the breakdown rows when there's nothing to break down — product rows already sum to the total.
        let hasModifiers = tax != 0 || discount != 0
        if hasModifiers {
            summaryItems.append(
                PKPaymentSummaryItem(
                    label: String.Localized.subtotal,
                    amount: makeApplePayAmount(
                        minorUnitsAmount: Decimal(totals.subtotal.minorUnitsAmount),
                        currency: currency
                    ),
                    type: .final
                )
            )
            if tax != 0 {
                summaryItems.append(
                    PKPaymentSummaryItem(
                        label: String.Localized.tax,
                        amount: makeApplePayAmount(minorUnitsAmount: Decimal(tax), currency: currency),
                        type: .final
                    )
                )
            }
            if discount != 0 {
                // `discount` is non-negative; flip the sign so Apple Pay shows it as a deduction.
                let amount = makeApplePayAmount(minorUnitsAmount: Decimal(discount), currency: currency)
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
                amount: makeApplePayAmount(
                    minorUnitsAmount: Decimal(totals.total.minorUnitsAmount),
                    currency: currency
                ),
                type: .final
            )
        )

        return summaryItems
    }

    private static func makeApplePayAmount(
        minorUnitsAmount: Decimal,
        currency: String?
    ) -> NSDecimalNumber {
        let amount = NSDecimalNumber(decimal: minorUnitsAmount)
            .multiplying(by: NSDecimalNumber.stp_decimalNumber(withAmount: 1, currency: currency))
        return amount.roundedForApplePay(currency: currency)
    }

    // Partial billing or shipping address from the Apple Pay sheet (no street until authorization).
    // Returns nil if there's no country to key tax on.
    private static func makeCheckoutAddress(from postalAddress: CNPostalAddress) -> CheckoutElementsController.Address? {
        guard let country = postalAddress.isoCountryCode.nonEmpty else {
            return nil
        }
        return CheckoutElementsController.Address(
            country: country,
            line1: nil,
            line2: nil,
            city: postalAddress.city.nonEmpty,
            state: postalAddress.state.nonEmpty,
            postalCode: postalAddress.postalCode.nonEmpty
        )
    }

    /// Builds the `PKPaymentRequest` for a Checkout Session's Apple Pay flow, including which
    /// billing/shipping contact fields Apple Pay must collect.
    static func makePaymentRequest(
        checkoutSession: CheckoutElementsController.Session,
        applePayConfirmationParameters: CheckoutElementsController.ApplePayConfirmationParameters
    ) -> PKPaymentRequest {
        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: applePayConfirmationParameters.merchantId,
            country: checkoutSession.merchantCountryCode,
            currency: checkoutSession.activePresentmentCurrency ?? "USD"
        )

        assert(!paymentRequest.merchantIdentifier.isEmpty, "You must set `applePayMerchantId` on `CheckoutElementsController.Configuration`.")

        let merchantLabel = applePayConfirmationParameters.merchantDisplayName
        paymentRequest.paymentSummaryItems = CheckoutApplePayContext.makeSummaryItems(for: checkoutSession, label: merchantLabel)

        if checkoutSession.collectsTaxFromBillingAddress {
            paymentRequest.requiredBillingContactFields.insert(.postalAddress)
        }

        if checkoutSession.email == nil {
            paymentRequest.requiredShippingContactFields.insert(.emailAddress)
        }

        if applePayConfirmationParameters.shippingAddressRequired {
            paymentRequest.requiredShippingContactFields.insert(.postalAddress)
            paymentRequest.requiredShippingContactFields.insert(.name)
            if let shippingAddress = checkoutSession.shippingAddress {
                paymentRequest.shippingContact = makeShippingContact(from: shippingAddress)
            }
        }

        if let defaults = applePayConfirmationParameters.defaultBillingDetails,
           defaults.address?.line1 != nil {
            paymentRequest.billingContact = makeBillingContact(from: defaults)
        }

        return paymentRequest
    }

    static func makeShippingContact(from shippingAddress: CheckoutElementsController.Session.ShippingAddress) -> PKContact {
        let contact = PKContact()
        if let name = shippingAddress.name {
            contact.name = PersonNameComponentsFormatter().personNameComponents(from: name)
        }

        let address = shippingAddress.address
        let postalAddress = CNMutablePostalAddress()
        postalAddress.isoCountryCode = address.country
        postalAddress.street = [address.line1, address.line2].compactMap { $0 }.joined(separator: "\n")
        postalAddress.city = address.city ?? ""
        postalAddress.state = address.state ?? ""
        postalAddress.postalCode = address.postalCode ?? ""
        contact.postalAddress = postalAddress
        return contact
    }

    static func makeBillingContact(
        from billingDetails: CheckoutElementsController.Configuration.Defaults.BillingDetails
    ) -> PKContact {
        let contact = PKContact()
        if let name = billingDetails.name {
            contact.name = PersonNameComponentsFormatter().personNameComponents(from: name)
        }
        if let address = billingDetails.address {
            let postalAddress = CNMutablePostalAddress()
            postalAddress.isoCountryCode = address.country
            postalAddress.street = [address.line1, address.line2].compactMap { $0 }.joined(separator: "\n")
            postalAddress.city = address.city ?? ""
            postalAddress.state = address.state ?? ""
            postalAddress.postalCode = address.postalCode ?? ""
            contact.postalAddress = postalAddress
        }
        return contact
    }

    private func _end() {
        authorizationController.delegate = nil
        shippingContactUpdateTask = nil
        paymentMethodUpdateTask = nil
        didFinish = true
    }

    private func restoreInitialTaxRegionIfNecessary() async {
        guard let checkoutWalletUpdater,
              checkoutWalletUpdater.currentTaxRegion != initialTaxRegion else {
            return
        }
        _ = try? await checkoutWalletUpdater.updateTaxRegionWithoutEnqueueing(
            address: initialTaxRegion,
            canUpdateWhileSheetPresented: true,
            confirmationSource: attribution.confirmingElement
        )
    }

    private func resume(with result: CheckoutElementsController.InternalConfirmResult) {
        guard let c = continuation else { return }
        continuation = nil
        c.resume(returning: result)
    }

    private func finishAndDismiss() {
        Task { @MainActor in
            await self.authorizationController.dismiss()
            self.resume(with: self.result ?? .canceled())
            self._end()
        }
    }

    private func makeShippingDetailsParams(from payment: PKPayment) -> STPPaymentIntentShippingDetailsParams? {
        guard let shippingContact = payment.shippingContact,
              let nameComponents = shippingContact.name else {
            return nil
        }

        let name = PersonNameComponentsFormatter.localizedString(from: nameComponents, style: .default)
        let shippingAddress = STPAddress(pkContact: shippingContact)

        // country is required by the API; skip shipping if it's absent (e.g. simulator fixtures).
        guard let line1 = shippingAddress.line1,
              let country = shippingAddress.country else {
            return nil
        }

        let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: line1)
        addressParams.line2 = shippingAddress.line2
        addressParams.city = shippingAddress.city
        addressParams.state = shippingAddress.state
        addressParams.postalCode = shippingAddress.postalCode
        addressParams.country = country

        let shippingDetailsParams = STPPaymentIntentShippingDetailsParams(address: addressParams, name: name)
        shippingDetailsParams.phone = shippingAddress.phone

        return shippingDetailsParams
    }
}
