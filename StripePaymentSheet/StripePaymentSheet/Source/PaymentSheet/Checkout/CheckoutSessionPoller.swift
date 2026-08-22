//
//  CheckoutSessionPoller.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/22/26.
//

import Foundation

protocol CheckoutSessionPollingAPIClient {
    func pollCheckoutSession(
        checkoutSessionId: String
    ) async throws -> PaymentPagePollResponse

    func retrieveCheckoutSession(
        checkoutSessionId: String
    ) async throws -> PaymentPagesAPIResponse
}

protocol CheckoutSessionPollingClock {
    func now() -> TimeInterval

    func sleep(for duration: TimeInterval) async throws
}

struct CheckoutSessionPoller {
    enum Error: Swift.Error {
        case paymentFailed(session: PaymentPagesAPIResponse)
    }

    private static let timeout: TimeInterval = 30

    /// The minimum elapsed time between the start of consecutive poll requests.
    private static let minimumTimeInterval: TimeInterval = 0.5

    private let apiClient: any CheckoutSessionPollingAPIClient
    private let clock: any CheckoutSessionPollingClock

    init(
        apiClient: any CheckoutSessionPollingAPIClient,
        clock: any CheckoutSessionPollingClock
    ) {
        self.apiClient = apiClient
        self.clock = clock
    }

    /// Returns after polling terminates or times out.
    ///
    /// Throws `Error.paymentFailed` after observing `requires_payment_method`
    /// and retrieving the full Checkout Session. Cancellation and full-session
    /// retrieval errors are also propagated.
    func poll(checkoutSessionId: String) async throws {
        // TODO: Implement Checkout Session polling.
        fatalError("CheckoutSessionPoller.poll is not implemented")
    }
}
