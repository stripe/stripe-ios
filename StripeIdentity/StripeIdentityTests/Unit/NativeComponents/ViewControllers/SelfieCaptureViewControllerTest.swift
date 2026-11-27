//
//  SelfieCaptureViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Stripe on 8/4/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import AVKit
import Foundation
@_spi(InternalOnlyAPI) import StripeCameraCoreTestUtils
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
import XCTest

// swift-format-ignore
@testable @_spi(InternalOnlyAPI) import StripeCameraCore

@testable import StripeIdentity

final class SelfieCaptureViewControllerTest: XCTestCase {
    private static let mockVerificationPage = try! VerificationPageMock.response200.make()

    private let mockCameraSession = MockTestCameraSession()
    private let mockConcurrencyManager = ImageScanningConcurrencyManagerMock()
    private let mockCameraPermissionsManager = MockCameraPermissionsManager()
    private let mockAppSettingsHelper = MockAppSettingsHelper()
    private let mockError = NSError(domain: "mock_error", code: 100)

    private var mockAnalyticsClient: MockAnalyticsClientV2!
    private var mockSheetController: VerificationSheetControllerMock!
    private var mockFaceScanner: FaceScannerMock!
    private var mockSelfieUploader: SelfieUploaderProtocol!

    override func setUp() {
        super.setUp()

        mockAnalyticsClient = .init()
        mockSheetController = .init(
            analyticsClient: IdentityAnalyticsClient(
                verificationSessionId: "",
                analyticsClient: mockAnalyticsClient
            )
        )
        mockFaceScanner = .init()
        mockSelfieUploader = SelfieUploaderMock()
    }

    func testRequestCameraAccessDeniedLogsAnalytics() {
        let vc = makeViewController()

        vc.viewWillAppear(false)
        mockCameraPermissionsManager.respondToRequest(granted: false)
        wait(for: [mockCameraPermissionsManager.didCompleteExpectation], timeout: 1)

        let analytic = mockAnalyticsClient.loggedAnalyticPayloads(
            withEventName: "camera_permission_denied"
        ).first
        XCTAssert(analytic: analytic, hasMetadata: "screen_name", withValue: "selfie")
        XCTAssert(
            analytic: analytic,
            hasMetadata: "camera_source",
            withValue: "camera_session"
        )
        XCTAssert(analytic: analytic, hasMetadata: "camera_event_kind", withValue: "permission")
        XCTAssert(analytic: analytic, hasMetadata: "camera_access_state", withValue: "denied")

        let errorAnalytic = mockAnalyticsClient.loggedAnalyticPayloads(
            withEventName: "camera_error"
        ).first
        XCTAssert(analytic: errorAnalytic, hasMetadata: "screen_name", withValue: "selfie")
        XCTAssert(
            analytic: errorAnalytic,
            hasMetadata: "camera_source",
            withValue: "camera_session"
        )
        XCTAssert(analytic: errorAnalytic, hasMetadata: "camera_event_kind", withValue: "permission")
        XCTAssert(analytic: errorAnalytic, hasMetadata: "camera_access_state", withValue: "denied")
        let error = (errorAnalytic?["event_metadata"] as? [String: Any])?["error"] as? [String: Any]
        XCTAssertEqual(error?["type"] as? String, "cameraPermissionDenied")
        XCTAssertEqual(error?["file"] as? String, "SelfieCaptureViewController.swift")
    }

    func testRequestCameraAccessGrantedLogsExistingAnalytic() {
        let vc = makeViewController()

        vc.viewWillAppear(false)
        mockCameraPermissionsManager.respondToRequest(granted: true)
        wait(for: [mockCameraPermissionsManager.didCompleteExpectation], timeout: 1)

        XCTAssertEqual(
            mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "camera_permission_granted")
                .count,
            1
        )
        XCTAssertEqual(
            mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "camera_permission_denied")
                .count,
            0
        )
        XCTAssertEqual(
            mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "camera_error").count,
            0
        )
    }

    func testCameraSessionFailedConfigureLogsAnalytics() {
        let vc = makeViewController()

        vc.viewWillAppear(false)
        mockCameraPermissionsManager.respondToRequest(granted: true)
        wait(for: [mockCameraPermissionsManager.didCompleteExpectation], timeout: 1)

        mockCameraSession.respondToConfigureSession(setupResult: .failed(error: mockError))
        wait(for: [mockCameraSession.configureSessionCompletionExp], timeout: 1)

        let analytic = mockAnalyticsClient.loggedAnalyticPayloads(
            withEventName: "camera_error"
        ).first
        XCTAssert(
            analytic: analytic,
            hasMetadataError: "error",
            withDomain: "mock_error",
            code: 100,
            fileName: "SelfieCaptureViewController.swift"
        )
        XCTAssert(analytic: analytic, hasMetadata: "screen_name", withValue: "selfie")
        XCTAssert(
            analytic: analytic,
            hasMetadata: "camera_source",
            withValue: "camera_session"
        )
        XCTAssert(analytic: analytic, hasMetadata: "camera_event_kind", withValue: "runtime_error")
    }

    func testAutoCaptureStatesDoNotShowBottomButton() {
        XCTAssertTrue(
            makeViewController(initialState: .initial).buttonViewModels.isEmpty
        )
        XCTAssertTrue(
            makeViewController(initialState: .scanning(.empty, .initialValue())).buttonViewModels.isEmpty
        )
        XCTAssertTrue(
            makeViewController(
                initialState: .saving(.empty, makeFaceCaptureData())
            ).buttonViewModels.isEmpty
        )
    }

    func testRestartAcceptsFramesBeforePreviousCameraStopCompletes() throws {
        // Given a sample timer that temporarily prevents collecting another frame
        let vc = makeViewController(initialState: .scanning(.empty, .initialValue()))
        let session = vc.imageScanningSession
        let sample = makeFaceCaptureData().first
        vc.imageScanningSessionDidScanImage(
            session,
            image: sample.image,
            scannerOutput: sample.scannerOutput,
            exifMetadata: nil,
            expectedClassification: .empty
        )
        XCTAssertFalse(vc.imageScanningSessionShouldScanCameraOutput(session))

        // When scanning stops and restarts without waiting for the camera to stop
        session.stopScanning()
        XCTAssertTrue(vc.imageScanningSessionShouldScanCameraOutput(session))
        session.startScanning()

        let sampleBuffer = try XCTUnwrap(
            CapturedImageMock.frontDriversLicense.image.convertToSampleBuffer()
        )
        let output = AVCaptureVideoDataOutput()
        session.captureOutput(
            output,
            didOutput: sampleBuffer,
            from: AVCaptureConnection(inputPorts: [], output: output)
        )
        mockConcurrencyManager.respondToScan(output: sample.scannerOutput)

        // Then the previous attempt's timer does not suppress the new frame
        XCTAssertEqual(mockConcurrencyManager.scanCallCount, 1)
        guard case .scanning(_, let scanningState) = session.state else {
            return XCTFail("Expected the new attempt to be scanning")
        }
        XCTAssertEqual(scanningState.frontSamples.count, 1)
        session.stopScanning()
    }

    func testStopCancelsPoseAcknowledgementWhileScannerIsDraining() {
        // Given a completed front capture waiting to advance to the next pose
        let sample = makeFaceCaptureData().first
        let frontSamples = Array(
            repeating: sample,
            count: Self.mockVerificationPage.selfie!.numSamples - 1
        )
        let vc = makeViewController(
            initialState: .scanning(.empty, .init(frontSamples: frontSamples)),
            enable3DFaceCapture: true
        )
        let session = vc.imageScanningSession
        vc.imageScanningSessionDidScanImage(
            session,
            image: sample.image,
            scannerOutput: sample.scannerOutput,
            exifMetadata: nil,
            expectedClassification: .empty
        )
        XCTAssertFalse(vc.imageScanningSessionShouldScanCameraOutput(session))
        let stoppedState = session.state

        // When stopping cannot complete before the acknowledgement timer's deadline
        mockConcurrencyManager.automaticallyCompletesReset = false
        session.stopScanning()
        XCTAssertTrue(vc.imageScanningSessionShouldScanCameraOutput(session))
        let acknowledgementDeadlinePassed = expectation(description: "Acknowledgement deadline passed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            acknowledgementDeadlinePassed.fulfill()
        }
        wait(for: [acknowledgementDeadlinePassed], timeout: 3)

        // Then the old callback cannot advance the pose or restart the timeout
        XCTAssertEqual(session.state, stoppedState)
        XCTAssertNotEqual(session.timeoutTimer?.isValid, true)
        mockConcurrencyManager.completePendingResets()
    }
}

private extension SelfieCaptureViewControllerTest {
    func makeViewController(
        initialState: SelfieCaptureViewController.State = .initial,
        enable3DFaceCapture: Bool = false
    ) -> SelfieCaptureViewController {
        return SelfieCaptureViewController(
            initialState: initialState,
            apiConfig: Self.mockVerificationPage.selfie!,
            enable3DFaceCapture: enable3DFaceCapture,
            sheetController: mockSheetController,
            cameraSession: mockCameraSession,
            selfieUploader: mockSelfieUploader,
            anyFaceScanner: .init(mockFaceScanner),
            concurrencyManager: mockConcurrencyManager,
            cameraPermissionsManager: mockCameraPermissionsManager,
            appSettingsHelper: mockAppSettingsHelper
        )
    }

    func makeFaceCaptureData() -> FaceCaptureData {
        let image = CapturedImageMock.frontDriversLicense.image.cgImage!
        let faceRect = CGRect(x: 0.3, y: 0.2, width: 0.4, height: 0.4)
        let samples: [FaceScannerInputOutput] = [0.7, 0.8, 0.9].map { score in
            FaceScannerInputOutput(
                image: image,
                scannerOutput: .init(
                    faceDetectorOutput: .init(
                        predictions: [
                            .init(
                                rect: faceRect,
                                score: score
                            ),
                        ]
                    ),
                    cameraProperties: nil,
                    motionBlurResult: nil,
                    isValid: true
                ),
                cameraExifMetadata: nil
            )
        }
        return FaceCaptureData(samples: samples)!
    }
}

private final class SelfieUploaderMock: SelfieUploaderProtocol {
    var uploadFuture: Future<SelfieUploader.FileData>?

    func uploadImages(_ capturedImages: FaceCaptureData) {
        // no-op
    }

    func reset() {
        uploadFuture = nil
    }
}
