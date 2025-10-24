//
//  AttestationConfirmationChallenge.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 10/24/25.
//

@_spi(STP) import StripeCore

actor AttestationConfirmationChallenge {
    private let stripeAttest: StripeAttest
    private var assertionHandle: StripeAttest.AssertionHandle?

    public init(stripeAttest: StripeAttest) {
        self.stripeAttest = stripeAttest
        Task { await stripeAttest.prepareAttestation() } // Intentionally not blocking loading/initialization!
    }

    // TODO: add timeout
    public func fetchAssertion() async -> StripeAttest.Assertion? {
        do {
            assertionHandle = try await stripeAttest.assert(canSyncState: false)
        } catch {
            assertionHandle = nil
        }
        return assertionHandle?.assertion
    }

    public func complete() {
        assertionHandle?.complete()
    }
}
