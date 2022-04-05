//
//  CardImageVerificationControllerTests.swift
//  StripeCardScanTests
//
//  Created by Jaime Park on 11/18/21.
//

@testable import StripeCardScan
import OHHTTPStubs
import StripeCoreTestUtils
import UIKit
import XCTest

class CardImageVerificationControllerTests: APIStubbedTestCase {
    private var result: CardImageVerificationSheetResult?
    private var resultExp: XCTestExpectation!
    private var verifyFramesRequestExp: XCTestExpectation!
    private var scanStatsRequestExp: XCTestExpectation!
    private var baseViewController: UIViewController!
    private var verificationSheetController: CardImageVerificationController!

    private let mockVerificationFrameData = VerificationFramesData(
        imageData: "image_data",
        viewfinderMargins: ViewFinderMargins(left: 0, upper: 0, right: 0, lower: 0)
    )

    override func setUp() {
        super.setUp()
        self.resultExp = XCTestExpectation(description: "CIV Sheet result has been stored")
        self.verifyFramesRequestExp = XCTestExpectation(description: "A verify frames request has been stubbed")
        self.scanStatsRequestExp = XCTestExpectation(description: "A scan stats request has been stubbed")
        self.baseViewController = UIViewController()

        var configuration = CardImageVerificationSheet.Configuration()
        configuration.apiClient = stubbedAPIClient()

        let verificationSheetController = CardImageVerificationController(
            intent: CIVIntentMockData.intent,
            configuration: configuration
        )
        verificationSheetController.delegate = self

        self.verificationSheetController = verificationSheetController
    }

    /// This test simulates the verification view controller closing on back button press
    func testFlowCanceled_Back() {
        stubUploadScanStats()

        /// Invoke a `VerifyCardAddViewController` being created by not passing an expected card
        verificationSheetController.present(with: nil, from: baseViewController)
        verificationSheetController.verifyViewControllerDidCancel(
            baseViewController,
            with: .back,
            scanAnalyticsManager:  ScanAnalyticsManager(configuration: .init())
        )

        guard case .canceled(reason: .back) = result else {
            XCTFail("Expected .canceled(reason: .back)")
            return
        }

        wait(for: [resultExp, scanStatsRequestExp], timeout: 1)
    }

    /// This test simulates the verification view controller closing by pressing the manual button
    func testFlowCanceled_Close() {
        stubUploadScanStats()

        /// Invoke a `VerifyCardAddViewController` being created by not passing an expected card
        verificationSheetController.present(with: nil, from: baseViewController)
        verificationSheetController.verifyViewControllerDidCancel(
            baseViewController,
            with: .closed,
            scanAnalyticsManager:  ScanAnalyticsManager(configuration: .init())
        )

        guard case .canceled(reason: .closed) = result else {
            XCTFail("Expected .canceled(reason: .closed)")
            return
        }

        wait(for: [resultExp, scanStatsRequestExp], timeout: 1)
    }

    /// This test simulates the verification view controller completing the scan flow
    func testFlowCompleted() {
        stubSubmitVerificationFrames()
        stubUploadScanStats()

        /// Invoke a `VerifyCardAddViewController` being created by not passing an expected card
        verificationSheetController.present(with: nil, from: baseViewController)

        /// Mock the event where the scanning is complete and the verification frames data is passed back to be submitted for completion
        verificationSheetController.verifyViewControllerDidFinish(
            baseViewController, verificationFramesData: [mockVerificationFrameData],
            scannedCard: ScannedCard(pan: "4242"),
            scanAnalyticsManager: ScanAnalyticsManager(configuration: .init())
        )

        /// Wait for submitVerificationFrames request to be made and the result to return
        wait(for: [resultExp, verifyFramesRequestExp, scanStatsRequestExp], timeout: 1)

        guard case .completed(scannedCard: ScannedCard(pan: "4242")) = result else {
            XCTFail("Expected .completed(scannedCard: ScannedCard(pan: \"4242\")")
            return
        }
    }
}

extension CardImageVerificationControllerTests: CardImageVerificationControllerDelegate {
    func cardImageVerificationController(_ controller: CardImageVerificationController, didFinishWithResult result: CardImageVerificationSheetResult) {
        self.result = result
        resultExp.fulfill()
    }
}

extension CardImageVerificationControllerTests {
    func stubSubmitVerificationFrames() {
        let mockResponse = "{}".data(using: .utf8)!

        /// Stub the request to submit verify frames
        stub { [weak self]  request in
            guard let requestUrl = request.url,
                  /// Check that the request is a POST request with an endpoint with the CIV id
                  requestUrl.absoluteString.contains("v1/card_image_verifications/\(CIVIntentMockData.id)/verify_frames"),
                  request.httpMethod == "POST"
            else {
                return false
            }

            self?.verifyFramesRequestExp.fulfill()
            return true
        } response: { request in
            return HTTPStubsResponse(data: mockResponse, statusCode: 200, headers: nil)
        }
    }

    func stubUploadScanStats() {
        let mockResponse = "{}".data(using: .utf8)!

        /// Stub the request to submit verify frames
        stub { [weak self]  request in
            guard let requestUrl = request.url,
                  /// Check that the request is a POST request with an endpoint with the CIV id
                  requestUrl.absoluteString.contains("v1/card_image_verifications/\(CIVIntentMockData.id)/scan_stats"),
                  request.httpMethod == "POST"
            else {
                return false
            }

            self?.scanStatsRequestExp.fulfill()
            return true
        } response: { request in
            return HTTPStubsResponse(data: mockResponse, statusCode: 200, headers: nil)
        }
    }
}
