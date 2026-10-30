//
//  ImageScanningConcurrencyManagerTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import CoreMedia
import Foundation
@_spi(InternalOnlyAPI) import StripeCameraCore
@_spi(InternalOnlyAPI) import StripeCameraCoreTestUtils
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
import XCTest

@testable import StripeIdentity

@MainActor
final class ImageScanningConcurrencyManagerTest: XCTestCase {
    func testScannerRunsOnCallerQueueBeforeScanImageReturns() async throws {
        // Given a scanner that records whether it ran on the camera queue
        let sampleBuffer = try XCTUnwrap(
            CapturedImageMock.frontDriversLicense.image.convertToSampleBuffer()
        )
        let pixelBuffer = try XCTUnwrap(CMSampleBufferGetImageBuffer(sampleBuffer))
        let scanner = ImageScannerMock<Int>(scanResult: .success(1))
        let callerQueueKey = DispatchSpecificKey<Void>()
        let callerQueue = DispatchQueue(label: "ImageScanningConcurrencyManagerTest.caller")
        callerQueue.setSpecific(key: callerQueueKey, value: ())
        var scannedOnCallerQueue = false
        scanner.scanHandler = {
            scannedOnCallerQueue = DispatchQueue.getSpecific(key: callerQueueKey) != nil
        }
        let manager = ImageScanningConcurrencyManager(
            sheetController: VerificationSheetControllerMock(),
            scannerName: .document,
            screenName: .documentCapture
        )
        let scanReturnedExp = expectation(description: "scanImage returned")
        let completionExp = expectation(description: "Scan completed")

        // When a frame is scanned from the camera queue
        callerQueue.async {
            manager.scanImage(
                with: AnyImageScanner(scanner),
                pixelBuffer: pixelBuffer,
                sampleBuffer: sampleBuffer,
                cameraSession: MockTestCameraSession(),
                completeOn: callerQueue,
                completion: { _ in completionExp.fulfill() }
            )
            // Then the scan already ran on the camera queue when `scanImage` returns
            XCTAssertTrue(scannedOnCallerQueue)
            scanReturnedExp.fulfill()
        }
        await fulfillment(of: [scanReturnedExp, completionExp], timeout: 1)
    }

    func testFailedScansReleaseSlotsAndLogErrors() async throws {
        // Given a scanner that always throws
        let sampleBuffer = try XCTUnwrap(
            CapturedImageMock.frontDriversLicense.image.convertToSampleBuffer()
        )
        let pixelBuffer = try XCTUnwrap(CMSampleBufferGetImageBuffer(sampleBuffer))
        let scanner = ImageScannerMock<Int>(scanResult: .failure(NSError(domain: "test", code: 1)))
        let mockAnalyticsClient = MockAnalyticsClientV2()
        let manager = ImageScanningConcurrencyManager(
            sheetController: VerificationSheetControllerMock(
                analyticsClient: IdentityAnalyticsClient(
                    verificationSessionId: "",
                    analyticsClient: mockAnalyticsClient
                )
            ),
            scannerName: .document,
            screenName: .documentCapture
        )
        let scanCount = kConcurrentImageScannerDefaultMaxConcurrentScans + 1
        let scansReturned = expectation(description: "All scans returned")
        let callerQueue = DispatchQueue(label: "ImageScanningConcurrencyManagerTest.caller")

        // When more frames are scanned than there are slots
        callerQueue.async {
            for _ in 0..<scanCount {
                manager.scanImage(
                    with: AnyImageScanner(scanner),
                    pixelBuffer: pixelBuffer,
                    sampleBuffer: sampleBuffer,
                    cameraSession: MockTestCameraSession(),
                    completeOn: callerQueue,
                    completion: { _ in XCTFail("A failed scan must not call completion") }
                )
            }
            scansReturned.fulfill()
        }

        // Then the third scan gets a slot, so each failure released its slot
        await fulfillment(of: [scansReturned], timeout: 1)
        // ...and each failure is logged once
        await fulfillment(
            of: [expectation(for: mockAnalyticsClient, keyPath: \.loggedAnalyticsPayloads.count, equalsToValue: scanCount)],
            timeout: 4
        )
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "generic_error").count, scanCount)
    }
}
