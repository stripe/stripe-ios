//
//  LinkURLGeneratorTests.swift
//  StripePaymentSheetTests
//

import Foundation

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@testable import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

class LinkURLGeneratorTests: XCTestCase {
    let testParams = LinkURLParams(linkMode: .pm,
                                  publishableKey: "pk_test_123",
                                  merchantInfo: LinkURLParams.MerchantInfo(businessName: "Test test", country: "US"),
                                  customerInfo: LinkURLParams.CustomerInfo(country: "US", email: "test@example.com"),
                                  paymentInfo: LinkURLParams.PaymentInfo(currency: "USD", amount: 100),
                                  returnUrl: URL(string: "stripesdk://")!,
                                  experiments: [],
                                  flags: [],
                                  loggerMetadata: [],
                                  locale: Locale.init(identifier: "en_US").toLanguageTag())
    
    func testURLCreation() {
        let url = try! LinkURLGenerator.url(params: testParams)
        XCTAssertEqual(url.absoluteString, "https://checkout.link.com/#eyJsb2dnZXJNZXRhZGF0YSI6W10sImN1c3RvbWVySW5mbyI6eyJjb3VudHJ5IjoiVVMiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20ifSwiZXhwZXJpbWVudHMiOltdLCJwYXltZW50SW5mbyI6eyJjdXJyZW5jeSI6IlVTRCIsImFtb3VudCI6MTAwfSwibG9jYWxlIjoiZW4tVVMiLCJwYXRoIjoibW9iaWxlX3BheSIsIm1lcmNoYW50SW5mbyI6eyJjb3VudHJ5IjoiVVMiLCJidXNpbmVzc05hbWUiOiJUZXN0IHRlc3QifSwicHVibGlzaGFibGVLZXkiOiJwa190ZXN0XzEyMyIsImxpbmtNb2RlIjoicG0iLCJyZXR1cm5VcmwiOiJzdHJpcGVzZGs6XC9cLyIsImZsYWdzIjpbXSwiaW50ZWdyYXRpb25UeXBlIjoibW9iaWxlIn0=")
    }
    
    func testURLCreationRegularUnicode() {
        var params = testParams
        params.customerInfo.email = "유니코드"
        let url = try! LinkURLGenerator.url(params: params)
        XCTAssertEqual(url.absoluteString, "https://checkout.link.com/#eyJsb2dnZXJNZXRhZGF0YSI6W10sImN1c3RvbWVySW5mbyI6eyJjb3VudHJ5IjoiVVMiLCJlbWFpbCI6IuycoOuLiOy9lOuTnCJ9LCJleHBlcmltZW50cyI6W10sInBheW1lbnRJbmZvIjp7ImN1cnJlbmN5IjoiVVNEIiwiYW1vdW50IjoxMDB9LCJsb2NhbGUiOiJlbi1VUyIsInBhdGgiOiJtb2JpbGVfcGF5IiwibWVyY2hhbnRJbmZvIjp7ImNvdW50cnkiOiJVUyIsImJ1c2luZXNzTmFtZSI6IlRlc3QgdGVzdCJ9LCJwdWJsaXNoYWJsZUtleSI6InBrX3Rlc3RfMTIzIiwibGlua01vZGUiOiJwbSIsInJldHVyblVybCI6InN0cmlwZXNkazpcL1wvIiwiZmxhZ3MiOltdLCJpbnRlZ3JhdGlvblR5cGUiOiJtb2JpbGUifQ==")
    }
    
    func testURLCreationHorribleUnicode() {
        var params = testParams
        params.customerInfo.email = String(bytes: [0xD8, 0x00] as [UInt8], encoding: .utf16BigEndian)! // Unpaired UTF-16 surrogates
        do {
            let _ = try LinkURLGenerator.url(params: params)
            XCTFail("Encoding should fail for invalid data")
        } catch {
            XCTAssertTrue(error as? EncodingError != nil)
        }
    }
}
