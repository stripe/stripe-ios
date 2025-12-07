//
//  URL+LinkBankPaymentMethodTests.swift
//  StripeCoreTests
//
//  Created by Mat Schmid on 2025-11-24.
//

@_spi(STP) import StripeCore
import XCTest

class URLLinkBankPaymentMethodTests: XCTestCase {

    // MARK: URL.extractLinkBankPaymentMethod()

    func testExtractLinkBankPaymentMethod_Success() throws {
        let urlString = "stripe-auth://link-accounts/success?payment_method_id=pm_1SX3G9CeQ8xWuVRgK52G5g1G&payment_method=eyJpZCI6InBtXzFTWDNHOUNlUTh4V3VWUmdLNTJHNWcxRyIsIm9iamVjdCI6InBheW1lbnRfbWV0aG9kIiwiYWxsb3dfcmVkaXNwbGF5IjoidW5zcGVjaWZpZWQiLCJiaWxsaW5nX2RldGFpbHMiOnsiYWRkcmVzcyI6eyJjaXR5IjpudWxsLCJjb3VudHJ5IjpudWxsLCJsaW5lMSI6bnVsbCwibGluZTIiOm51bGwsInBvc3RhbF9jb2RlIjpudWxsLCJzdGF0ZSI6bnVsbH0sImVtYWlsIjpudWxsLCJuYW1lIjpudWxsLCJwaG9uZSI6bnVsbCwidGF4X2lkIjpudWxsfSwiY3JlYXRlZCI6MTc2NDAwNDE0NSwiY3VzdG9tZXIiOm51bGwsImxpbmsiOnsiZW1haWwiOiJtYXRzQHN0cmlwZS5jb20iLCJmaW5hbmNpYWxfY29ubmVjdGlvbnNfYWNjb3VudCI6bnVsbCwiZnVuZGluZ19zb3VyY2UiOnsiZmluZ2VycHJpbnQiOiJMVGZpdzJKeXdYSHptTzZTIiwiaW5zdGl0dXRpb25faWNvbl9wbmciOiJodHRwczovL2Iuc3RyaXBlY2RuLmNvbS9jb25uZWN0aW9ucy1zdGF0aWNzLXNydi9hc3NldHMvQnJhbmRJY29uLS1zdHJpcGUtNHgucG5nIiwiaW5zdGl0dXRpb25fbG9nb19wbmciOiJodHRwczovL2Iuc3RyaXBlY2RuLmNvbS9jb25uZWN0aW9ucy1zdGF0aWNzLXNydi9hc3NldHMvQnJhbmRJY29uLS1tb2NrLTR4LnBuZyIsImluc3RpdHV0aW9uX25hbWUiOiJQYXltZW50IFN1Y2Nlc3MiLCJsYXN0NCI6IjY3ODkifX0sImxpdmVtb2RlIjpmYWxzZSwidHlwZSI6ImxpbmsifQ%3D%3D&bank_name=Payment+Success&last4=6789"
        let url = try XCTUnwrap(URL(string: urlString))

        let paymentMethod = try url.extractLinkBankPaymentMethod()

        XCTAssertNotNil(paymentMethod)
        XCTAssertEqual(paymentMethod?.id, "pm_1SX3G9CeQ8xWuVRgK52G5g1G")
    }

    func testExtractLinkBankPaymentMethod_MissingParameter() throws {
        let urlString = "stripe-auth://link-accounts/success?bank_name=Payment+Success&last4=6789"
        let url = try XCTUnwrap(URL(string: urlString))

        let paymentMethod = try url.extractLinkBankPaymentMethod()

        XCTAssertNil(paymentMethod, "Should return nil when payment_method parameter is missing")
    }

    func testExtractLinkBankPaymentMethod_InvalidBase64() throws {
        let urlString = "stripe-auth://link-accounts/success?payment_method=not-valid-base64!!!"
        let url = try XCTUnwrap(URL(string: urlString))

        XCTAssertThrowsError(try url.extractLinkBankPaymentMethod()) { error in
            XCTAssertTrue(
                error is URL.LinkBankPaymentMethodError,
                "Should throw LinkBankPaymentMethodError for invalid base64"
            )
            if case URL.LinkBankPaymentMethodError.failedToBase64Decode = error {
                // Expected error
            } else {
                XCTFail("Expected failedToBase64Decode error")
            }
        }
    }

    func testExtractLinkBankPaymentMethod_InvalidJSON() throws {
        // Valid base64 but invalid JSON
        let invalidJSON = "not a json object"
        let base64Encoded = Data(invalidJSON.utf8).base64EncodedString()
        let urlString = "stripe-auth://link-accounts/success?payment_method=\(base64Encoded)"
        let url = try XCTUnwrap(URL(string: urlString))

        XCTAssertThrowsError(try url.extractLinkBankPaymentMethod()) { error in
            XCTAssertTrue(
                error is DecodingError,
                "Should throw DecodingError for invalid JSON"
            )
        }
    }

    func testExtractLinkBankPaymentMethod_MissingRequiredField() throws {
        // Valid JSON but missing required "id" field
        let jsonWithoutID = "{\"type\":\"link\"}"
        let base64Encoded = Data(jsonWithoutID.utf8).base64EncodedString()
        let urlString = "stripe-auth://link-accounts/success?payment_method=\(base64Encoded)"
        let url = try XCTUnwrap(URL(string: urlString))

        XCTAssertThrowsError(try url.extractLinkBankPaymentMethod()) { error in
            XCTAssertTrue(
                error is DecodingError,
                "Should throw DecodingError for missing required field"
            )
        }
    }

    // MARK: URL.extractQueryValue(forKey:)

    func testExtractQueryValue_SuccessAndFailureCases() throws {
        let urlString = "stripe-auth://link-accounts/success?bank_name=Payment%20Success&last4=6789"
        let url = try XCTUnwrap(URL(string: urlString))

        XCTAssertEqual(url.extractQueryValue(forKey: "bank_name"), "Success")
        XCTAssertEqual(url.extractQueryValue(forKey: "last4"), "6789")
        XCTAssertNil(url.extractQueryValue(forKey: "payment_method_id"))
    }
}
