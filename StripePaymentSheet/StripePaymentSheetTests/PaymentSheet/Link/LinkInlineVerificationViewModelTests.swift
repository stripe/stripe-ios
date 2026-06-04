//
//  LinkInlineVerificationViewModelTests.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet

@MainActor
final class LinkInlineVerificationViewModelTests: STPNetworkStubbingTestCase {
    func testStartVerificationStoresRateLimitError() async throws {
        let originalMaxRetries = StripeAPI.maxRetries
        StripeAPI.maxRetries = 0
        defer { StripeAPI.maxRetries = originalMaxRetries }

        stub(condition: isPath("/v1/consumers/sessions/start_verification")) { _ in
            LinkVerificationTestHelpers.makeStartVerificationRateLimitResponse()
        }

        let sut = makeSUT()

        await sut.startVerification()

        let error = try XCTUnwrap(sut.startVerificationError as NSError?)
        XCTAssertEqual(error._stp_error_code, "consumer_verification_max_attempts_exceeded")
    }
}

private extension LinkInlineVerificationViewModelTests {
    func makeSUT() -> LinkInlineVerificationViewModel {
        let account = PaymentSheetLinkAccount._testValue(
            email: "jane.diaz@email.com",
            isRegistered: true,
            displayablePaymentDetails: nil
        )
        return LinkInlineVerificationViewModel(account: account, appearance: .default)
    }
}
