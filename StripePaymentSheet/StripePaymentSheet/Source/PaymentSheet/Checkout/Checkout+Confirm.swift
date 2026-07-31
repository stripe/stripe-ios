//
//  Checkout+Confirm.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

// MARK: - Confirm

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {

    /// Confirms the Checkout Session using the currently selected payment method.
    ///
    /// - Parameter presentingViewController: The view controller used to present authentication
    ///   UI (e.g. 3D Secure). Pass `nil` and the SDK will use the topmost view controller from
    ///   the key window.
    /// - Returns: A ``ConfirmResult`` indicating whether the payment succeeded, was canceled,
    ///   or failed with an error.
    public func confirm(from presentingViewController: UIViewController? = nil) async -> ConfirmResult {
        // Wait for any in-flight session updates before confirming.
        do {
            try await awaitPendingOperations()
        } catch {
            return .failed(error)
        }

        // Apple Pay has its own presentation flow and bypasses the PaymentElement confirm path.
        if session.paymentOption?.paymentMethodType == "apple_pay" {
            return await confirmWithApplePay(from: presentingViewController)
        }

        return await confirmWithPaymentElement(from: presentingViewController)
    }
}

// MARK: - Private helpers

extension Checkout {

    /// Presents Apple Pay and confirms the Checkout Session using `CheckoutApplePayContextClosureDelegate`.
    private func confirmWithApplePay(from presentingViewController: UIViewController?) async -> ConfirmResult {
        guard configuration.applePayConfiguration != nil else {
            return .failed(CheckoutError.apiError(message: "Apple Pay is selected but no Apple Pay configuration was provided."))
        }

        return await withCheckedContinuation { continuation in
            let context = CheckoutApplePayContextClosureDelegate.makeApplePayContext(for: self) { result in
                continuation.resume(returning: result)
            }

            guard let context else {
                continuation.resume(returning: .failed(CheckoutError.apiError(message: "Unable to create Apple Pay context. Verify that Apple Pay is supported on this device and your merchant identifier is correct.")))
                return
            }

            let window = presentingViewController?.view?.window
            context.presentApplePay(from: window)
        }
    }

    /// Confirms the Checkout Session using the PaymentElement's embedded flow and converts
    /// the result to a `ConfirmResult`.
    private func confirmWithPaymentElement(from presentingViewController: UIViewController?) async -> ConfirmResult {
        let embedded = paymentElement.embeddedPaymentElement

        if let vc = presentingViewController {
            embedded.presentingViewController = vc
        }

        // EmbeddedPaymentElement.confirm() handles session serialization internally when
        // a Checkout instance is present, so we do not wrap this call in enqueueSessionUpdate.
        let result = await embedded.confirm()
        return result.asCheckoutConfirmResult(paymentStatus: session.status?.paymentStatus)
    }
}

// MARK: - PaymentSheetResult → ConfirmResult

extension PaymentSheetResult {
    /// Converts a `PaymentSheetResult` to a `Checkout.ConfirmResult`.
    ///
    /// - Parameter paymentStatus: The current session payment status, used to populate the
    ///   `succeeded` case. Defaults to `.unknown` when `nil`.
    func asCheckoutConfirmResult(paymentStatus: Checkout.PaymentStatus?) -> Checkout.ConfirmResult {
        switch self {
        case .completed:
            return .succeeded(paymentStatus: paymentStatus ?? .unknown)
        case .canceled:
            return .canceled
        case .failed(let error):
            return .failed(error)
        }
    }
}
