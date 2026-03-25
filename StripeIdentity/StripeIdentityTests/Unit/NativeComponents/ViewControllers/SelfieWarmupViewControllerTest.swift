//
//  SelfieWarmupViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 8/15/23.
//

import Foundation
@_spi(STP) import StripeCameraCoreTestUtils
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
import XCTest

// swift-format-ignore
@testable @_spi(STP) import StripeCameraCore

@testable import StripeIdentity

final class SelfieWarmupViewControllerTest: XCTestCase {
    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    private var vc: SelfieWarmupViewController!
    private let mockSheetController = VerificationSheetControllerMock()

    override func setUp() {
        super.setUp()

        vc = try! SelfieWarmupViewController(
            sheetController: mockSheetController
        )
    }

    func testTapContinue() {
        // Tap continue button
        vc.flowViewModel.buttons.first?.didTap()

        // Verify transitioned to selfie capture
        XCTAssertTrue(mockSheetController.transitionedToSelfieCapture)
    }

}

final class SelfieCaptureViewControllerTest: XCTestCase {
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
}

private extension SelfieCaptureViewControllerTest {
    func makeViewController(
        initialState: SelfieCaptureViewController.State = .initial
    ) -> SelfieCaptureViewController {
        return SelfieCaptureViewController(
            initialState: initialState,
            apiConfig: SelfieWarmupViewControllerTest.mockVerificationPage.selfie!,
            sheetController: mockSheetController,
            cameraSession: mockCameraSession,
            selfieUploader: mockSelfieUploader,
            anyFaceScanner: .init(mockFaceScanner),
            concurrencyManager: mockConcurrencyManager,
            cameraPermissionsManager: mockCameraPermissionsManager,
            appSettingsHelper: mockAppSettingsHelper
        )
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
