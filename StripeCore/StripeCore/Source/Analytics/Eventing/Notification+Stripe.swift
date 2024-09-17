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

    public enum EventName: Equatable {
        case presentedSheet
        case selectedPaymentMethodType(SelectedPaymentMethodType)
        case displayedPaymentMethodForm(DisplayedPaymentMethodForm)

        case startedInteractionWithPaymentMethodForm(StartedInteractionWithPaymentMethodForm)
        case completedPaymentMethodForm(CompletedPaymentMethodForm)
        case tappedConfirmButton(TappedConfirmButton)

        case selectedSavedPaymentMethod(SelectedSavedPaymentMethod)
        case removedSavedPaymentMethod(RemovedSavedPaymentMethod)
    }

    public struct SelectedPaymentMethodType: Equatable {
        public let paymentMethodType: String
        internal init(paymentMethodType: String) {
            self.paymentMethodType = paymentMethodType
        }
    }
    public struct DisplayedPaymentMethodForm: Equatable {
        public let paymentMethodType: String
        internal init(paymentMethodType: String) {
            self.paymentMethodType = paymentMethodType
        }
    }
    public struct StartedInteractionWithPaymentMethodForm: Equatable {
        public let paymentMethodType: String
        internal init(paymentMethodType: String) {
            self.paymentMethodType = paymentMethodType
        }
    }
    public struct CompletedPaymentMethodForm: Equatable {
        public let paymentMethodType: String
        internal init(paymentMethodType: String) {
            self.paymentMethodType = paymentMethodType
        }
    }
    public struct TappedConfirmButton: Equatable {
        public let paymentMethodType: String
        internal init(paymentMethodType: String) {
            self.paymentMethodType = paymentMethodType
        }
    }
    public struct SelectedSavedPaymentMethod: Equatable {
        public let paymentMethodType: String
        internal init(paymentMethodType: String) {
            self.paymentMethodType = paymentMethodType
        }

    }
    public struct RemovedSavedPaymentMethod: Equatable {
        public let paymentMethodType: String
        internal init(paymentMethodType: String) {
            self.paymentMethodType = paymentMethodType
        }
    }
}
