//
//  PaymentPagePollResponse.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/22/26.
//

@_spi(STP) import StripeCore

/// The small response returned by the Checkout Session poll endpoint.
///
/// This response is used to decide when to stop waiting. It does not contain
/// enough data to replace a `PaymentPagesAPIResponse`.
struct PaymentPagePollResponse: Decodable, Equatable {
    let sessionId: String
    let state: State
    let paymentObjectStatus: PaymentObjectStatus?

    enum State: String, SafeEnumDecodable {
        case active
        case pendingAsyncCustomerAction = "pending_async_customer_action"
        case processingSubscription = "processing_subscription"
        case processingAsyncPayment = "processing_async_payment"
        case processingSyncPayment = "processing_sync_payment"
        case succeeded
        case invalid
        case expired
        case unparsable = ""
    }

    enum PaymentObjectStatus: String, SafeEnumDecodable {
        case canceled
        case processing
        case requiresAction = "requires_action"
        case requiresCapture = "requires_capture"
        case requiresConfirmation = "requires_confirmation"
        case requiresPaymentMethod = "requires_payment_method"
        case requiresReauthorization = "requires_reauthorization"
        case succeeded
        case unparsable = ""
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case state
        case paymentObjectStatus = "payment_object_status"
    }
}
