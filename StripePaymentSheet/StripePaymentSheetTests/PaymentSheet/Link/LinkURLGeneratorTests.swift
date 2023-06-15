//
//  LinkURLGeneratorTests.swift
//  StripePaymentSheetTests
//

import Foundation

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@_spi(STP) @_spi(ExperimentalPaymentSheetDecouplingAPI) @testable import StripePaymentSheet

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
                                   locale: Locale.init(identifier: "en_US").toLanguageTag())

    func testURLCreation() {
        let url = try! LinkURLGenerator.url(params: testParams)
        XCTAssertEqual(url.absoluteString, "https://checkout.link.com/#eyJsb2dnZXJNZXRhZGF0YSI6e30sImN1c3RvbWVySW5mbyI6eyJjb3VudHJ5IjoiVVMiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20ifSwiZXhwZXJpbWVudHMiOnt9LCJwYXltZW50VXNlckFnZW50IjoidGVzdCIsImxvY2FsZSI6ImVuLVVTIiwicGF0aCI6Im1vYmlsZV9wYXkiLCJwYXltZW50SW5mbyI6eyJjdXJyZW5jeSI6IlVTRCIsImFtb3VudCI6MTAwfSwibWVyY2hhbnRJbmZvIjp7ImNvdW50cnkiOiJVUyIsImJ1c2luZXNzTmFtZSI6IlRlc3QgdGVzdCJ9LCJwdWJsaXNoYWJsZUtleSI6InBrX3Rlc3RfMTIzIiwibGlua01vZGUiOiJwbSIsImZsYWdzIjp7fSwiaW50ZWdyYXRpb25UeXBlIjoibW9iaWxlIn0=")
    }

    func testURLCreationRegularUnicode() {
        var params = testParams
        params.customerInfo.email = "유니코드"
        let url = try! LinkURLGenerator.url(params: params)
        XCTAssertEqual(url.absoluteString, "https://checkout.link.com/#eyJsb2dnZXJNZXRhZGF0YSI6e30sImN1c3RvbWVySW5mbyI6eyJjb3VudHJ5IjoiVVMiLCJlbWFpbCI6IuycoOuLiOy9lOuTnCJ9LCJleHBlcmltZW50cyI6e30sInBheW1lbnRVc2VyQWdlbnQiOiJ0ZXN0IiwibG9jYWxlIjoiZW4tVVMiLCJwYXRoIjoibW9iaWxlX3BheSIsInBheW1lbnRJbmZvIjp7ImN1cnJlbmN5IjoiVVNEIiwiYW1vdW50IjoxMDB9LCJtZXJjaGFudEluZm8iOnsiY291bnRyeSI6IlVTIiwiYnVzaW5lc3NOYW1lIjoiVGVzdCB0ZXN0In0sInB1Ymxpc2hhYmxlS2V5IjoicGtfdGVzdF8xMjMiLCJsaW5rTW9kZSI6InBtIiwiZmxhZ3MiOnt9LCJpbnRlZ3JhdGlvblR5cGUiOiJtb2JpbGUifQ==")
    }

    func testURLCreationHorribleUnicode() {
        var params = testParams
        params.customerInfo.email = String(bytes: [0xD8, 0x00] as [UInt8], encoding: .utf16BigEndian)! // Unpaired UTF-16 surrogates
        do {
            _ = try LinkURLGenerator.url(params: params)
            XCTFail("Encoding should fail for invalid data")
        } catch {
            XCTAssertTrue(error as? EncodingError != nil)
        }
    }

    func testURLParamsFromConfig() async {
        let config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD")) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        let intent = Intent.deferredIntent(elementsSession: STPElementsSession.emptyElementsSession, intentConfig: intentConfig)
        let params = try! await LinkURLGenerator.linkParams(configuration: config, intent: intent)

        let expectedParams = LinkURLParams(paymentObject: .link_payment_method,
                                           publishableKey: config.apiClient.publishableKey!,
                                           paymentUserAgent: PaymentsSDKVariant.paymentUserAgent,
                                           merchantInfo: LinkURLParams.MerchantInfo(businessName: "xctest", country: "US"),
                                           customerInfo: LinkURLParams.CustomerInfo(country: "US", email: nil),
                                           paymentInfo: LinkURLParams.PaymentInfo(currency: "USD", amount: 100),
                                           experiments: [:],
                                           flags: [:],
                                           loggerMetadata: [:],
                                           locale: Locale.init(identifier: "en_US").toLanguageTag())

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
