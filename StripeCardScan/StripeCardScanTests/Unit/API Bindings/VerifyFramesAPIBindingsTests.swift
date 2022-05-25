//
//  VerifyFramesAPIBindingsTests.swift
//  StripeCardScanTests
//
//  Created by Jaime Park on 11/24/21.
//

@testable import StripeCardScan
@testable @_spi(STP) import StripeCore
import XCTest

/// These tests are used to see if the encodable object has been encoded as expected by checking the following:
/// 1. The keys are properly set (snake case)
/// 2. The values are properly set
class VerifyFramesAPIBindingsTests: XCTestCase {
    /*
     The expected structure:
     {
        client_secret: "secret",
        verification_frames_data: "verification_frames_data"
     }
     */
    func testVerifyFrames() throws {
        let verifyFrames = VerifyFrames(
            clientSecret: CIVIntentMockData.clientSecret,
            verificationFramesData: "verification_frames_data"
        )

        /// encodeJSONDictionary used when forming the request body
        let jsonDictionary = try verifyFrames.encodeJSONDictionary()

        XCTAssertEqual(jsonDictionary["client_secret"] as! String, CIVIntentMockData.clientSecret)
        XCTAssertEqual(jsonDictionary["verification_frames_data"] as! String, "verification_frames_data")
    }

    /*
     The expected structure:
     {
        image_data: "image_data",
        viewfinder_margins: {
            left: 0,
            upper: 0,
            right: 0,
            lower: 0
        }
     }
     */
    func testVerificationFramesData() throws {
        let testData = "image_data".data(using: .utf8)!

        let verificationFramesData = VerificationFramesData(
            imageData: testData,
            viewfinderMargins: ViewFinderMargins(
                left: 0,
                upper: 0,
                right: 0,
                lower: 0
            )
        )

        /// encodeJSONDictionary used when forming the request body
        let jsonDictionary = try verificationFramesData.encodeJSONDictionary()
        let jsonDictionaryViewfinderMargins = jsonDictionary["viewfinder_margins"] as! [String: Any]

        XCTAssertEqual(jsonDictionary["image_data"] as! String, "aW1hZ2VfZGF0YQ==")
        XCTAssertEqual(jsonDictionaryViewfinderMargins["left"] as! Int, 0)
        XCTAssertEqual(jsonDictionaryViewfinderMargins["upper"] as! Int, 0)
        XCTAssertEqual(jsonDictionaryViewfinderMargins["right"] as! Int, 0)
        XCTAssertEqual(jsonDictionaryViewfinderMargins["lower"] as! Int, 0)
    }
}
