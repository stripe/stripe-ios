//
//  ImageScanningConcurrencyManagerTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import CoreMedia
import Foundation
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCameraCoreTestUtils
import XCTest

@testable import StripeIdentity

@MainActor
final class ImageScanningConcurrencyManagerTest: XCTestCase {
    func testScannerRunsOnCallerQueueBeforeResultHandling() async throws {
        let sampleBuffer = try XCTUnwrap(
            CapturedImageMock.frontDriversLicense.image.convertToSampleBuffer()
        )
        let pixelBuffer = try XCTUnwrap(CMSampleBufferGetImageBuffer(sampleBuffer))
        let scanner = ImageScannerMock<Int>(scanResult: .success(1))
        let callerQueueKey = DispatchSpecificKey<Void>()
        let callerQueue = DispatchQueue(label: "ImageScanningConcurrencyManagerTest.caller")
        callerQueue.setSpecific(key: callerQueueKey, value: ())
        let scanExpectation = expectation(description: "Image scanned")
        scanner.scanHandler = {
            XCTAssertNotNil(DispatchQueue.getSpecific(key: callerQueueKey))
            scanExpectation.fulfill()
        }
        let manager = ImageScanningConcurrencyManager(
            sheetController: VerificationSheetControllerMock(),
            scannerName: .document,
            screenName: .documentCapture
        )
        let completionSignal = DispatchSemaphore(value: 0)
        manager.concurrentQueue.suspend()

        callerQueue.async {
            manager.scanImage(
                with: AnyImageScanner(scanner),
                pixelBuffer: pixelBuffer,
                sampleBuffer: sampleBuffer,
                cameraSession: MockTestCameraSession(),
                completeOn: callerQueue,
                completion: { _ in completionSignal.signal() }
            )
        }

        await fulfillment(of: [scanExpectation], timeout: 1)
        XCTAssertEqual(completionSignal.wait(timeout: .now() + 0.1), .timedOut)

        manager.concurrentQueue.resume()
        XCTAssertEqual(completionSignal.wait(timeout: .now() + 1), .success)
    }
}
