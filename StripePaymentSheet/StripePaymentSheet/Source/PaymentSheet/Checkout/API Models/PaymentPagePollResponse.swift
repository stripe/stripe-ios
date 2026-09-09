//
//  PaymentPagePollResponse.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/22/26.
//

/// The small response returned by the Checkout Session poll endpoint.
///
/// This response is used to decide when to stop waiting. It does not contain
/// enough data to replace a `PaymentPagesAPIResponse`.
struct PaymentPagePollResponse: Decodable, Equatable {
    let sessionId: String
    let state: State
    let paymentObjectStatus: PaymentObjectStatus?

    enum State: String, Decodable {
        case active
        case failedAsyncPayment = "failed_async_payment"
        case pendingAsyncCustomerAction = "pending_async_customer_action"
        case processingSubscription = "processing_subscription"
        case processingAsyncPayment = "processing_async_payment"
        case processingSyncPayment = "processing_sync_payment"
        case succeeded
        case invalid
        case expired
    }

    /// The client only needs to distinguish a failed payment from every other
    /// payment object status. The poll response is not used as session data.
    enum PaymentObjectStatus: Decodable, Equatable {
        case requiresPaymentMethod
        case other

        init(from decoder: Decoder) throws {
            let rawValue = try decoder.singleValueContainer().decode(String.self)
            self = rawValue == "requires_payment_method" ? .requiresPaymentMethod : .other
        }
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case state
        case paymentObjectStatus = "payment_object_status"
    }
}
