//
//  EmbeddedPaymentElementTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 10/14/24.
//

@testable@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable@_spi(STP) import StripePaymentsTestUtils
import XCTest

@_spi(EmbeddedPaymentElementPrivateBeta) @_spi(STP) @testable import StripePaymentSheet

@MainActor
class EmbeddedPaymentElementTest: STPNetworkStubbingTestCase {
    lazy var configuration: EmbeddedPaymentElement.Configuration = {
        var config = EmbeddedPaymentElement.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        config.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        return config
    }()
    let paymentIntentConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD"), paymentMethodTypes: ["card"]) { _, _, _ in
        // These tests don't confirm, so this is unused
    }
    let setupIntentConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession), paymentMethodTypes: ["card"]) { _, _, _ in
        // These tests don't confirm, so this is unused
    }

    // MARK: - `update` tests

    func testUpdate() async throws {
        STPAnalyticsClient.sharedClient._testLogHistory = []
        CustomerPaymentOption.setDefaultPaymentMethod(.applePay, forCustomer: nil)

        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        // ...its intent should match the initial intent config...
        XCTAssertFalse(sut.loadResult.intent.isSettingUp)
        XCTAssertTrue(sut.loadResult.intent.isPaymentIntent)

        // ...and updating the intent config should succeed...
        let update1Result = await sut.update(intentConfiguration: setupIntentConfig)
        XCTAssertEqual(update1Result, .succeeded)
        XCTAssertTrue(sut.loadResult.intent.isSettingUp)
        XCTAssertFalse(sut.loadResult.intent.isPaymentIntent)

        // ...updating the intent config multiple times...
        // ...(using the completion block based API this time)...
        let secondUpdateExpectation = expectation(description: "Second update completes")
        sut.update(intentConfiguration: paymentIntentConfig) { update2Result in
            // ...should succeed.
            XCTAssertEqual(update2Result, .succeeded)
            XCTAssertFalse(sut.loadResult.intent.isSettingUp)
            XCTAssertTrue(sut.loadResult.intent.isPaymentIntent)
            // TODO: Test paymentOption updates correctly. 

            // Sanity check that the analytics...
            let analytics = STPAnalyticsClient.sharedClient._testLogHistory
            let loadStartedEvents = analytics.filter { $0["event"] as? String == "mc_load_started" }
            let loadSucceededEvents = analytics.filter { $0["event"] as? String == "mc_load_succeeded" }
            // ...have the expected # of start and succeeded events...
            XCTAssertEqual(loadStartedEvents.count, 3)
            XCTAssertEqual(loadSucceededEvents.count, 3)
            // ..and all have the same session id...
            let sessionID = analytics.first?["session_id"] as? String
            (loadStartedEvents + loadSucceededEvents).map { $0["session_id"] as? String }.forEach {
                XCTAssertEqual($0, sessionID)
            }

            secondUpdateExpectation.fulfill()
        }
        await fulfillment(of: [secondUpdateExpectation])
    }

    func testUpdateFails() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        // ...updating w/ an invalid intent config should fail...
        var intentConfig = paymentIntentConfig
        intentConfig.mode = .setup(currency: "Invalid currency", setupFutureUsage: .offSession)
        let updateResult = await sut.update(intentConfiguration: intentConfig)
        switch updateResult {
        case .failed(error: let error):
            print(error.nonGenericDescription)
        default:
            break
        }

        // Updating should succeed after failing to update...
        let secondUpdateExpectation = expectation(description: "Second update succeeds")
        intentConfig.mode = .setup(currency: "USD", setupFutureUsage: .offSession)
        // ...(using the completion block based API this time)...
        sut.update(intentConfiguration: intentConfig) { update2Result in
            XCTAssertEqual(update2Result, .succeeded)
            secondUpdateExpectation.fulfill()
        }
        await fulfillment(of: [secondUpdateExpectation])
    }

    func testUpdateCancelsInFlightUpdate() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        // ...updating...
        async let _updateResult = await sut.update(intentConfiguration: paymentIntentConfig)
        // ...and immediately updating again, before the 1st update finishes...
        async let _updateResult2 = await sut.update(intentConfiguration: setupIntentConfig)
        let updateResult = await _updateResult // Unfortunate workaround b/c XCTAssertEqual doesn't support concurrency
        let updateResult2 = await _updateResult2
        // ...should cancel the 1st update
        XCTAssertEqual(updateResult, .canceled)
        XCTAssertEqual(updateResult2, .succeeded)
        XCTAssertTrue(sut.loadResult.intent.isSettingUp)
    }

}

extension EmbeddedPaymentElementTest: EmbeddedPaymentElementDelegate {
    // TODO: Test delegates are called
    func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {}

    func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {}
}

extension EmbeddedPaymentElement.UpdateResult: @retroactive Equatable {
    public static func == (lhs: StripePaymentSheet.EmbeddedPaymentElement.UpdateResult, rhs: StripePaymentSheet.EmbeddedPaymentElement.UpdateResult) -> Bool {
        switch (lhs, rhs) {
        case (.succeeded, .succeeded): return true
        case let (.failed(lhsError), .failed(rhsError)): return lhsError.nonGenericDescription == rhsError.nonGenericDescription
        case (.canceled, .canceled): return true
        default: return false
        }
    }
}
