//
//  Notification+Stripe.swift
//  StripeCore
//

import Foundation

/**
 * WARNING: These events are intended to be used for analytics purposes ONLY. This API is highly volatile and is expected to change without notice.  There are no
 * guarantees about the accuracy, correctness, or stability of when these events are fired nor the data associated with them.
 */
@_spi(MobilePaymentElementEventingBeta)
public extension Notification.Name {
    static let mobilePaymentElement = Notification.Name("MobilePaymentElement")
}

@_spi(MobilePaymentElementEventingBeta)
public struct MobilePaymentElementEvent {
    public let eventName: String
    public let metadata: [String: Any?]
}
