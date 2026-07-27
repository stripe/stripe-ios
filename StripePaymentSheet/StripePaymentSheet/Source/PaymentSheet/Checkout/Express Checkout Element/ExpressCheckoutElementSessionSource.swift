//
//  ExpressCheckoutElementSessionSource.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/27/26.
//

import Combine
import Foundation

/// Provides the current Checkout Session without exposing Checkout itself.
@MainActor
final class ExpressCheckoutElementSessionSource: ObservableObject {
    @Published private(set) var session: Checkout.Session

    private var sessionCancellable: AnyCancellable?

    init(
        initialSession: Checkout.Session,
        sessionPublisher: Published<Checkout.Session>.Publisher
    ) {
        session = initialSession
        sessionCancellable = sessionPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.session = session
            }
    }
}
