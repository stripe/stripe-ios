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
                                   paymentUserAgent: "test",
                                   merchantInfo: LinkURLParams.MerchantInfo(businessName: "Test test", country: "US"),
                                   customerInfo: LinkURLParams.CustomerInfo(country: "US", email: "test@example.com"),
                                   paymentInfo: LinkURLParams.PaymentInfo(currency: "USD", amount: 100),
                                   experiments: [:],
                                   flags: [:],
                                   loggerMetadata: [:],
                                   locale: Locale.init(identifier: "en_US").toLanguageTag(),
                                   ctaType: .pay
    )

    func testURLCreation() {
        let url = try! LinkURLGenerator.url(params: testParams)
        XCTAssertEqual(url.absoluteString, "https://checkout.link.com/#eyJjdGFUeXBlIjoicGF5IiwiY3VzdG9tZXJJbmZvIjp7ImNvdW50cnkiOiJVUyIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSJ9LCJleHBlcmltZW50cyI6e30sImZsYWdzIjp7fSwiaW50ZWdyYXRpb25UeXBlIjoibW9iaWxlIiwibG9jYWxlIjoiZW4tVVMiLCJsb2dnZXJNZXRhZGF0YSI6e30sIm1lcmNoYW50SW5mbyI6eyJidXNpbmVzc05hbWUiOiJUZXN0IHRlc3QiLCJjb3VudHJ5IjoiVVMifSwicGF0aCI6Im1vYmlsZV9wYXkiLCJwYXltZW50SW5mbyI6eyJhbW91bnQiOjEwMCwiY3VycmVuY3kiOiJVU0QifSwicGF5bWVudE9iamVjdCI6ImxpbmtfcGF5bWVudF9tZXRob2QiLCJwYXltZW50VXNlckFnZW50IjoidGVzdCIsInB1Ymxpc2hhYmxlS2V5IjoicGtfdGVzdF8xMjMifQ==")
    }

    func testURLCreationRegularUnicode() {
        var params = testParams
        params.customerInfo.email = "유니코드"
        _ = try! LinkURLGenerator.url(params: params)
        // Just make sure it doesn't fail
    }

    func testURLCreationHorribleUnicode() {
        var params = testParams
        params.customerInfo.email = String(bytes: [0xD8, 0x00] as [UInt8], encoding: .utf16BigEndian)! // Unpaired UTF-16 surrogates
        let url = try! LinkURLGenerator.url(params: params)
        XCTAssertEqual(url.absoluteString, "https://checkout.link.com/#eyJjdGFUeXBlIjoicGF5IiwiY3VzdG9tZXJJbmZvIjp7ImNvdW50cnkiOiJVUyIsImVtYWlsIjoi77+9In0sImV4cGVyaW1lbnRzIjp7fSwiZmxhZ3MiOnt9LCJpbnRlZ3JhdGlvblR5cGUiOiJtb2JpbGUiLCJsb2NhbGUiOiJlbi1VUyIsImxvZ2dlck1ldGFkYXRhIjp7fSwibWVyY2hhbnRJbmZvIjp7ImJ1c2luZXNzTmFtZSI6IlRlc3QgdGVzdCIsImNvdW50cnkiOiJVUyJ9LCJwYXRoIjoibW9iaWxlX3BheSIsInBheW1lbnRJbmZvIjp7ImFtb3VudCI6MTAwLCJjdXJyZW5jeSI6IlVTRCJ9LCJwYXltZW50T2JqZWN0IjoibGlua19wYXltZW50X21ldGhvZCIsInBheW1lbnRVc2VyQWdlbnQiOiJ0ZXN0IiwicHVibGlzaGFibGVLZXkiOiJwa190ZXN0XzEyMyJ9")
    }

    func testURLParamsFromConfig() async {
        let config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD")) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        let intent = Intent.deferredIntent(elementsSession: STPElementsSession.emptyElementsSession, intentConfig: intentConfig)

        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()
        let sessionID = AnalyticsHelper.shared.sessionID!

        let params = try! LinkURLGenerator.linkParams(configuration: config, intent: intent)

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
                                           ctaType: .pay)

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
