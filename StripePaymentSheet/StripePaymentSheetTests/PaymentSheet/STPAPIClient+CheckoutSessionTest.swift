//
//  STPAPIClient+CheckoutSessionTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 1/15/26.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
import XCTest

final class STPAPIClientCheckoutSessionTest: STPNetworkStubbingTestCase {

    func testInitCheckoutSession() async throws {
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let checkoutSessionId = "cs_test_a1NZGwsFXlRiOPIHiGBJrh9dNdrxepbNl8NFvyff3xp4wtBK2PkNnBEKWg"

        let response = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId)

        // Verify checkout session fields
        let checkoutSession = response.checkoutSession
        XCTAssertEqual(checkoutSession.stripeId, checkoutSessionId)
        XCTAssertEqual(checkoutSession.mode, .payment)
        XCTAssertEqual(checkoutSession.status, .open)
        XCTAssertEqual(checkoutSession.paymentStatus, .unpaid)
        XCTAssertEqual(checkoutSession.currency, "usd")
        XCTAssertFalse(checkoutSession.livemode)
        XCTAssertTrue(checkoutSession.paymentMethodTypes.contains(.card))
        XCTAssertTrue(checkoutSession.paymentMethodTypes.contains(.USBankAccount))

        // Verify elements session fields
        let elementsSession = response.elementsSession
        XCTAssertTrue(elementsSession.sessionID.hasPrefix("elements_session_"))
        XCTAssertEqual(elementsSession.merchantCountryCode, "US")
        XCTAssertTrue(elementsSession.orderedPaymentMethodTypes.contains(.card))
    }
}
