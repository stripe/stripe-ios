//
//  ExpressCheckoutElementDelegate.swift
//  StripePaymentSheet
//

/// Delegate for `ExpressCheckoutElement` payment lifecycle events.
@_spi(STP)
@MainActor
public protocol ExpressCheckoutElementDelegate: AnyObject {

    /// Called when the customer completes, cancels, or fails to complete a payment.
    func expressCheckoutElement(
        _ element: ExpressCheckoutElement,
        didCompleteWith result: PaymentSheetResult
    )
}
