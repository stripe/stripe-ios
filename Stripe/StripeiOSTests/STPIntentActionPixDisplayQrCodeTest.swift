//
//  STPIntentActionPixDisplayQrCodeTest.swift
//  StripeiOSTests
//

import Foundation
@testable@_spi(STP) import Stripe

final class STPIntentActionPixDisplayQrCodeTest: XCTestCase {
    func testDecodesPixDisplayQrCode() throws {
        let response: [AnyHashable: Any] = [
            "type": "pix_display_qr_code",
            "pix_display_qr_code": [
                "data": "pix-copy-and-paste-data",
                "image_url_png": "https://qr.stripe.com/pix.png",
                "image_url_svg": "https://qr.stripe.com/pix.svg",
                "expires_at": 1_700_000_000,
                "hosted_instructions_url": "https://payments.stripe.com/pix/instructions/test",
            ],
        ]

        let nextAction = try XCTUnwrap(STPIntentAction.decodedObject(fromAPIResponse: response))
        let pix = try XCTUnwrap(nextAction.pixDisplayQrCode)

        XCTAssertEqual(nextAction.type, .pixDisplayQrCode)
        XCTAssertEqual(pix.data, "pix-copy-and-paste-data")
        XCTAssertEqual(pix.imageURLPNG, URL(string: "https://qr.stripe.com/pix.png"))
        XCTAssertEqual(pix.imageURLSVG, URL(string: "https://qr.stripe.com/pix.svg"))
        XCTAssertEqual(pix.expiresAt, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(
            pix.hostedInstructionsURL,
            URL(string: "https://payments.stripe.com/pix/instructions/test")
        )
    }

    func testMissingHostedInstructionsURLFailsDecoding() {
        let response: [AnyHashable: Any] = [
            "type": "pix_display_qr_code",
            "pix_display_qr_code": ["data": "pix-copy-and-paste-data"],
        ]

        XCTAssertEqual(STPIntentAction.decodedObject(fromAPIResponse: response)?.type, .unknown)
    }
}
