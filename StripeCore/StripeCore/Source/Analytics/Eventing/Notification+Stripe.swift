//
//  Notification+Stripe.swift
//  StripeCore
//

import Foundation

/**
 * WARNING: These events are intended to be used for analytics purposes ONLY. This API is volatile and is expected to change.
 * There are no guarantees about the accuracy, correctness, or stability of when these events are fired nor the data associated with them.
 */
@_spi(MobilePaymentElementEventingBeta)
public extension Notification.Name {
    /// The name of the notification used to send notifications for Mobile Payment Element
    static let mobilePaymentElement = Notification.Name("MobilePaymentElement")
}

@_spi(MobilePaymentElementEventingBeta)
/// The object type of the NSNotification's object.
public struct MobilePaymentElementEvent {

    /// The name of the event
    public let eventName: Name

    /// Associated metadata with the event
    public let metadata: [MetadataKey: Any?]

    public enum Name {
        case presentedSheet
        case selectedPaymentMethodType
        case displayedPaymentMethodForm

        case startedInteractionWithPaymentMethodForm
        case completedPaymentMethodForm
        case tappedConfirmButton

        case selectedSavedPaymentMethod
        case removedSavedPaymentMethod
    }

    public enum MetadataKey {
        case paymentMethodType
    }
}
