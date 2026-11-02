//
//  CheckoutClientPollResponse.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/22/26.
//

/// The response returned by CheckoutClient's /poll endpoint.
struct CheckoutClientPollResponse: Decodable, Equatable {
    let sessionId: String
    /// Determines whether polling should continue
    let confirmationStatus: ConfirmationStatus
    /// The latest Session status
    let status: CheckoutController.Session.Status
    /// The latest Session payment status
    let paymentStatus: CheckoutController.Session.Status.PaymentStatus

    enum ConfirmationStatus: String, Decodable {
        /// No confirmation attempt has been recorded. Unexpected after an accepted /confirm; stop polling and send an unexpected error analytic.
        case notStarted = "not_started"
        /// Confirmation is still in progress. Continue polling.
        case pending
        /// Confirmation succeeded. Stop polling; the payment may still be awaiting settlement or capture.
        case succeeded
        /// Confirmation failed. Stop polling and return failure, even if the Session status is complete.
        case failed
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "id"
        case confirmationStatus = "confirmation_status"
        case status
        case paymentStatus = "payment_status"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        confirmationStatus = try container.decode(ConfirmationStatus.self, forKey: .confirmationStatus)

        paymentStatus = try container.decode(CheckoutController.Session.Status.PaymentStatus.self, forKey: .paymentStatus)

        status = try CheckoutController.Session.Status.decode(
            from: container,
            forKey: .status,
            paymentStatus: paymentStatus
        )
    }
}
