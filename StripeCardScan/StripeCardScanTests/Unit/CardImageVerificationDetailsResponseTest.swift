//
//  CardImageVerificationDetailsResponseTest.swift
//  StripeCardScanTests
//
//  Created by Scott Grant on 5/11/22.
//

@testable @_spi(STP) import StripeCardScan
@testable @_spi(STP) import StripeCore

import XCTest

class CardImageVerificationDetailsResponseTest: XCTestCase {

    func testExample() throws {
        let json = """
            {
                "accepted_image_configs": {
                    "default_settings": {
                        "compression_ratio": 0.8,
                        "image_size": [
                            1080,
                            1920
                        ]
                    },
                    "format_settings": {
                        "heic": {
                            "compression_ratio": 0.5
                        },
                        "webp": {
                            "compression_ratio": 0.7,
                            "image_size": [
                                2160,
                                1920
                            ]
                        }
                    },
                    "preferred_formats": [
                        "heic",
                        "webp",
                        "jpeg"
                    ]
                },
                "expected_card": {
                    "last4": "9012",
                    "issuer": "Visa"
                }
            }
            """
        let jsonData = json.data(using: .utf8)!

        let responseObject: CardImageVerificationDetailsResponse =
            try StripeJSONDecoder.decode(jsonData: jsonData)

        let acceptedImageConfigs = responseObject.acceptedImageConfigs

        let heicSettings = acceptedImageConfigs?.imageSettings(format: .heic)
        XCTAssertNotNil(heicSettings)

        if let heicSettings = heicSettings {
            XCTAssertEqual(heicSettings.compressionRatio!, 0.5)
            XCTAssertEqual(heicSettings.imageSize!, [1080.0, 1920.0])
        }

        let jpegSettings =  acceptedImageConfigs?.imageSettings(format: .jpeg)
        XCTAssertNotNil(jpegSettings)

        if let jpegSettings = jpegSettings {
            XCTAssertEqual(jpegSettings.compressionRatio!, 0.8)
            XCTAssertEqual(jpegSettings.imageSize!, [1080.0, 1920.0])
        }

        let webpSettings =  acceptedImageConfigs?.imageSettings(format: .webp)
        XCTAssertNotNil(webpSettings)

        if let webpSettings = webpSettings {
            XCTAssertEqual(webpSettings.compressionRatio!, 0.7)
            XCTAssertEqual(webpSettings.imageSize!, [2160.0, 1920.0])
        }
    }
}
