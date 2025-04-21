//
//  Notification+Stripe.swift
//  StripeCore
//

import Foundation

@_spi(MobilePaymentElementAnalyticEventBeta)
public extension Notification.Name {
    /// These events are intended to be used for analytics purposes ONLY.
    ///
    /// A notification posted by Mobile Payment Element for analytics purposes.
    static let mobilePaymentElement = Notification.Name("MobilePaymentElement")
}

@_spi(MobilePaymentElementAnalyticEventBeta)
/// The object type of the NSNotification's object.
public struct MobilePaymentElementAnalyticEvent {

    /// The name of the event
    public let name: Name

    public enum Name: Equatable {
        /// Sheet is presented
        case presentedSheet
        /// Selected a different payment method type
        case selectedPaymentMethodType(SelectedPaymentMethodType)
        /// Payment method form for was displayed
        case displayedPaymentMethodForm(DisplayedPaymentMethodForm)

        /// User interacted with a payment method form
        case startedInteractionWithPaymentMethodForm(StartedInteractionWithPaymentMethodForm)
        /// All mandatory fields for the payment method form have been completed
        case completedPaymentMethodForm(CompletedPaymentMethodForm)
        /// User tapped on the confirm button
        case tappedConfirmButton(TappedConfirmButton)

        /// User selected a saved payment method
        case selectedSavedPaymentMethod(SelectedSavedPaymentMethod)
        /// User removed a saved payment method
        case removedSavedPaymentMethod(RemovedSavedPaymentMethod)
    }

    /// Details of the .selectedPaymentMethodType event
    public struct SelectedPaymentMethodType: Equatable {
        /// The payment method type
        public let paymentMethodType: String
    }

    /// Details of the .displayedPaymentMethodForm event
    public struct DisplayedPaymentMethodForm: Equatable {
        /// The payment method type
        public let paymentMethodType: String
    }

    /// Details of the .startedInteractionWithPaymentMethodForm event
    public struct StartedInteractionWithPaymentMethodForm: Equatable {
        /// The payment method type
        public let paymentMethodType: String
    }

    /// Details of the .completedPaymentMethodForm event
    public struct CompletedPaymentMethodForm: Equatable {
        /// The payment method type
        public let paymentMethodType: String
    }

    /// Details of the .tappedConfirmButton event
    public struct TappedConfirmButton: Equatable {
        /// The payment method type
        public let paymentMethodType: String
    }

    /// Details of the .selectedSavedPaymentMethod event
    public struct SelectedSavedPaymentMethod: Equatable {
        /// The payment method type
        public let paymentMethodType: String
    }

    /// Details of the .removedSavedPaymentMethod event
    public struct RemovedSavedPaymentMethod: Equatable {
        /// The payment method type
        public let paymentMethodType: String
    }
}
