//
//  PassiveCaptchaTests.swift
//  StripePaymentsTests
//
//  Created by Joyce Qin on 8/21/25.
//

@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePaymentsTestUtils
import XCTest

class PassiveCaptchaTests: XCTestCase {
    func testPassiveCaptcha() async {
        // OCS mobile test key from https://dashboard.hcaptcha.com/sites/edit/143aadb6-fb60-4ab6-b128-f7fe53426d4a
        let passiveCaptcha = PassiveCaptcha(siteKey: "143aadb6-fb60-4ab6-b128-f7fe53426d4a", rqdata: nil)
        let timeoutNs: UInt64 = 6_000_000_000 // 6s
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptcha: passiveCaptcha, testConfiguration: PassiveCaptchaChallenge.TestConfiguration(timeout: timeoutNs))
        let hcaptchaToken = await passiveCaptchaChallenge.fetchToken()
        XCTAssertNotNil(hcaptchaToken)
    }
    
    func testPassiveCaptchaTimeout() async {
        let passiveCaptcha = PassiveCaptcha(siteKey: "143aadb6-fb60-4ab6-b128-f7fe53426d4a", rqdata: nil)
        let shortTimeoutNs: UInt64 = 0
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptcha: passiveCaptcha, testConfiguration: PassiveCaptchaChallenge.TestConfiguration(timeout: shortTimeoutNs))
        let hcaptchaToken = await passiveCaptchaChallenge.fetchToken()
        XCTAssertNil(hcaptchaToken)
    }
}

class PassiveCaptchaNetworkTests: STPNetworkStubbingTestCase {
    var apiClient: STPAPIClient!

    override func setUp() {
        super.setUp()
        self.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
    }
    lazy var configuration: PaymentSheet.Configuration = {
        var config = PaymentSheet.Configuration()
        config.apiClient = apiClient
        config.applePay = .init(merchantId: "foo", merchantCountryCode: "US")
        return config
    }()

    func testPassiveCaptchaDoesNotBlockLoad() async throws {
        let passiveCaptcha = PassiveCaptcha(siteKey: "143aadb6-fb60-4ab6-b128-f7fe53426d4a", rqdata: nil)
        let timeoutNs: UInt64 = 30_000_000_000
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptcha: passiveCaptcha, testConfiguration: PassiveCaptchaChallenge.TestConfiguration(timeout: timeoutNs, delayValidation: true))
        await passiveCaptchaChallenge.start()
        let expectation = XCTestExpectation(description: "Load")
        let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(types: ["card"])
        PaymentSheetLoader.load(mode: .paymentIntentClientSecret(clientSecret), configuration: self.configuration, analyticsHelper: .init(integrationShape: .complete, configuration: configuration), integrationShape: .complete) { result in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: STPTestingNetworkRequestTimeout)
        let hcaptchaToken = await passiveCaptchaChallenge.fetchToken()
        XCTAssertNil(hcaptchaToken)
    }
}
