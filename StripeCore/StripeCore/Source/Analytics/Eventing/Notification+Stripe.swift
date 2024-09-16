//
//  Notification+Stripe.swift
//  StripeCore
//

import Foundation

@_spi(MobilePaymentElementEventingBeta)
public extension Notification.Name {
    /// WARNING: These events are intended to be used for analytics purposes ONLY. This API is volatile and is expected to change.
    /// There are no guarantees about the accuracy, correctness, or stability of when these events are fired nor the data associated with them.
    ///
    /// A notification posted by Mobile Payment Element for analytics purposes.
    static let mobilePaymentElement = Notification.Name("MobilePaymentElement")
}

@_spi(MobilePaymentElementEventingBeta)
/// The object type of the NSNotification's object.
public struct MobilePaymentElementEvent {

    /// The name of the event
    public let eventName: EventName

    /// Associated metadata with the event
    public let metadata: [MetadataKey: Any?]

    public enum EventName {
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
