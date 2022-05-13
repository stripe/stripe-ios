//
//  ScanAnalyticsManagerTests.swift
//  StripeCardScanTests
//
//  Created by Jaime Park on 5/10/22.
//

@testable @_spi(STP) import StripeCardScan
import OHHTTPStubs
import StripeCoreTestUtils
import XCTest

class ScanAnalyticsManagerTests: XCTestCase {
    private var scanAnalyticsManager: ScanAnalyticsManager!
    private var generatePayloadExp: XCTestExpectation!

    override func setUp() {
        super.setUp()
        self.scanAnalyticsManager = ScanAnalyticsManager()
        self.generatePayloadExp = expectation(description: "Successfully generated the scan analytics payload")
    }

    /// This test checks that the scan analytics manager aggregates tasks and generates the payload object properly
    func testGeneratePayload() {
        let startTime = Date()
        let payloadInfo = ScanAnalyticsPayload.PayloadInfo(imageCompressionType: "heic", imageCompressionQuality: 0.8, imagePayloadSize: 4000)

        /// Log scan activity repeating and non-repeating tasks
        scanAnalyticsManager.setScanSessionStartTime(time: startTime)
        scanAnalyticsManager.logCameraPermissionsTask(success: false)
        scanAnalyticsManager.logMainLoopImageProcessedRepeatingTask(.init(executions: 100))
        scanAnalyticsManager.logPayloadInfo(with: payloadInfo)

        scanAnalyticsManager.logScanActivityTask(event: .firstImageProcessed)
        scanAnalyticsManager.logTorchSupportTask(supported: false)

        /// Override tasks when values have changed
        scanAnalyticsManager.logCameraPermissionsTask(success: true)
        scanAnalyticsManager.logTorchSupportTask(supported: true)

        scanAnalyticsManager.generateScanAnalyticsPayload(with: .init()) { [weak self] scanAnalyticsPayload in
            guard let payload = scanAnalyticsPayload else {
                XCTFail("Did not generate scan analytics payload")
                return
            }

            self?.generatePayloadExp.fulfill()

            /// Check the populated configuration and payload info
            XCTAssertEqual(payload.configuration.strictModeFrames, 0)
            XCTAssertEqual(payload.payloadInfo, payloadInfo)

            /// Check the populated scan activity
            let payloadScanStats = payload.scanStats
            XCTAssertEqual(payloadScanStats.tasks.cameraPermission.first?.result, ScanAnalyticsEvent.cameraPermissionSuccess.rawValue)
            XCTAssertEqual(payloadScanStats.tasks.torchSupported.first?.result, ScanAnalyticsEvent.torchSupported.rawValue)
            XCTAssertEqual(payloadScanStats.tasks.scanActivity.first?.result, ScanAnalyticsEvent.firstImageProcessed.rawValue)
            XCTAssertEqual(payloadScanStats.repeatingTasks.mainLoopImagesProcessed, .init(executions: 100))
        }

        wait(for: [generatePayloadExp], timeout: 1)
    }

    /// This test checks that the scan analytics manager resets properly
    func testReset() {
        let startTime = Date()
        /// Log scan activity repeating and non-repeating tasks
        scanAnalyticsManager.setScanSessionStartTime(time: startTime)
        scanAnalyticsManager.logCameraPermissionsTask(success: false)
        scanAnalyticsManager.logMainLoopImageProcessedRepeatingTask(.init(executions: 100))
        scanAnalyticsManager.logScanActivityTaskFromStartTime(event: .firstImageProcessed)
        scanAnalyticsManager.logTorchSupportTask(supported: false)

        /// Reset the scan analytics manager
        scanAnalyticsManager.reset()

        scanAnalyticsManager.generateScanAnalyticsPayload(with: .init()) { [weak self] scanAnalyticsPayload in
            guard let payload = scanAnalyticsPayload else {
                XCTFail("Did not generate scan analytics payload")
                return
            }

            self?.generatePayloadExp.fulfill()

            /// Check the populated configuration
            XCTAssertEqual(payload.configuration.strictModeFrames, 0)
            XCTAssertNil(payload.payloadInfo, "A reset scan analytics manager should have a nil payload info")

            /// Check the reset scan activity
            let payloadScanStats = payload.scanStats
            XCTAssertEqual(payloadScanStats.tasks.cameraPermission.first?.result, ScanAnalyticsEvent.unknown.rawValue)
            XCTAssertEqual(payloadScanStats.tasks.torchSupported.first?.result, ScanAnalyticsEvent.unknown.rawValue)
            XCTAssertEqual(payloadScanStats.repeatingTasks.mainLoopImagesProcessed, .init(executions: -1))
            XCTAssert(payloadScanStats.tasks.scanActivity.isEmpty, "A reset scan analytics manager should have an empty scan activity list")
        }

        wait(for: [generatePayloadExp], timeout: 1)
    }
}
