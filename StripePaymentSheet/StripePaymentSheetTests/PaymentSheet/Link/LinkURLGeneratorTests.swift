//
//  LinkURLGeneratorTests.swift
//  StripePaymentSheetTests
//

import Foundation

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

class LinkURLGeneratorTests: XCTestCase {
    let testParams = LinkURLParams(paymentObject: .link_payment_method,
                                   publishableKey: "pk_test_123",
                                   stripeAccount: "acct_1234",
                                   paymentUserAgent: "test",
                                   merchantInfo: LinkURLParams.MerchantInfo(businessName: "Test test", country: "US"),
                                   customerInfo: LinkURLParams.CustomerInfo(country: "US", email: "test@example.com"),
                                   paymentInfo: LinkURLParams.PaymentInfo(currency: "USD", amount: 100),
                                   experiments: [:],
                                   flags: [:],
                                   loggerMetadata: [:],
                                   locale: Locale.init(identifier: "en_US").toLanguageTag(),
                                   intentMode: .payment,
                                   setupFutureUsage: false
    )

    func testURLCreation() {
        let url = try! LinkURLGenerator.url(params: testParams)
        XCTAssertEqual(url.absoluteString, "https://checkout.link.com/#eyJjdXN0b21lckluZm8iOnsiY291bnRyeSI6IlVTIiwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIn0sImV4cGVyaW1lbnRzIjp7fSwiZmxhZ3MiOnt9LCJpbnRlZ3JhdGlvblR5cGUiOiJtb2JpbGUiLCJpbnRlbnRNb2RlIjoicGF5bWVudCIsImxvY2FsZSI6ImVuLVVTIiwibG9nZ2VyTWV0YWRhdGEiOnt9LCJtZXJjaGFudEluZm8iOnsiYnVzaW5lc3NOYW1lIjoiVGVzdCB0ZXN0IiwiY291bnRyeSI6IlVTIn0sInBhdGgiOiJtb2JpbGVfcGF5IiwicGF5bWVudEluZm8iOnsiYW1vdW50IjoxMDAsImN1cnJlbmN5IjoiVVNEIn0sInBheW1lbnRPYmplY3QiOiJsaW5rX3BheW1lbnRfbWV0aG9kIiwicGF5bWVudFVzZXJBZ2VudCI6InRlc3QiLCJwdWJsaXNoYWJsZUtleSI6InBrX3Rlc3RfMTIzIiwic2V0dXBGdXR1cmVVc2FnZSI6ZmFsc2UsInN0cmlwZUFjY291bnQiOiJhY2N0XzEyMzQifQ==")
    }

    func testURLCreationRegularUnicode() {
        var params = testParams
        params.customerInfo.email = "유니코드"
        _ = try! LinkURLGenerator.url(params: params)
        // Just make sure it doesn't fail
    }

    func testURLParamsFromConfig() async {
        let config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD")) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        let intent = Intent.deferredIntent(intentConfig: intentConfig)

        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()
        let sessionID = AnalyticsHelper.shared.sessionID!

        let params = try! LinkURLGenerator.linkParams(configuration: config, intent: intent, elementsSession: .emptyElementsSession)

        let expectedParams = LinkURLParams(paymentObject: .link_payment_method,
                                           publishableKey: config.apiClient.publishableKey!,
                                           paymentUserAgent: PaymentsSDKVariant.paymentUserAgent,
                                           merchantInfo: LinkURLParams.MerchantInfo(businessName: "StripePaymentSheetTestHostApp", country: "US"),
                                           customerInfo: LinkURLParams.CustomerInfo(country: "US", email: nil),
                                           paymentInfo: LinkURLParams.PaymentInfo(currency: "USD", amount: 100),
                                           experiments: [:],
                                           flags: [:],
                                           loggerMetadata: ["mobile_session_id": sessionID],
                                           locale: Locale.init(identifier: "en_US").toLanguageTag(),
                                           intentMode: .payment,
                                           setupFutureUsage: false)

        XCTAssertEqual(params, expectedParams)
    }
}

extension STPElementsSession {
    // Should use the one from StripeiOSTests, but we don't have good infrastructure to share these
    // and we're not using any details from it.
    static var emptyElementsSession: STPElementsSession {
        let apiResponse: [String: Any] = ["payment_method_preference": ["ordered_payment_method_types": ["123"],
                                                                        "country_code": "US", ] as [String: Any],
                                          "session_id": "123",
                                          "apple_pay_preference": "enabled",
        ]
        return STPElementsSession.decodedObject(fromAPIResponse: apiResponse)!
    }
}

// Just for the purposes of this test. No need to add the (tiny) overhead of Equatable to the published binary
extension LinkURLParams: Equatable {
    public static func == (lhs: StripePaymentSheet.LinkURLParams, rhs: StripePaymentSheet.LinkURLParams) -> Bool {
        let encoder = JSONEncoder()
        // deterministic plz
        encoder.outputFormatting = .sortedKeys
        return try! encoder.encode(lhs) == encoder.encode(rhs)
    }
}
