//
//  IdentityAnalyticsClient.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/7/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

enum IdentityAnalyticsClientError: AnalyticLoggableError {
    /// `startTrackingTimeToScreen` was called twice in a row without calling
    /// `stopTrackingTimeToScreenAndLogIfNeeded`
    case timeToScreenAlreadyStarted(
        alreadyStartedForScreen: IdentityAnalyticsClient.ScreenName?,
        requestedForScreen: IdentityAnalyticsClient.ScreenName?
    )

    func analyticLoggableSerializeForLogging() -> [String : Any] {
        var payload: [String: Any] = [
            "domain": (self as NSError).domain
        ]
        switch self {
        case .timeToScreenAlreadyStarted(let alreadyStartedForScreen, let requestedForScreen):
            payload["type"] = "timeToScreenAlreadyStarted"
            if let alreadyStartedForScreen = alreadyStartedForScreen {
                payload["previous_tracked_screen"] = alreadyStartedForScreen.rawValue
            }
            if let requestedForScreen = requestedForScreen {
                payload["new_tracked_screen"] = requestedForScreen.rawValue
            }
        }
        return payload
    }
}

/// Wrapper for AnalyticsClient that formats Identity-specific analytics
final class IdentityAnalyticsClient {

    enum EventName: String {
        // MARK: UI
        case sheetPresented = "sheet_presented"
        case sheetClosed = "sheet_closed"
        case verificationFailed = "verification_failed"
        case verificationCanceled = "verification_canceled"
        case verificationSucceeded = "verification_succeeded"
        case screenAppeared = "screen_presented"
        case cameraError = "camera_error"
        case cameraPermissionDenied = "camera_permission_denied"
        case cameraPermissionGranted = "camera_permission_granted"
        case documentCaptureTimeout = "document_timeout"
        case selfieCaptureTimeout = "selfie_timeout"
        // MARK: Performance
        case averageFPS = "average_fps"
        case modelPerformance = "model_performance"
        case imageUpload = "image_upload"
        case timeToScreen = "time_to_screen"
        // MARK: Errors
        case genericError = "generic_error"
    }

    enum ScreenName: String {
        case biometricConsent = "consent"
        case documentTypeSelect = "document_select"
        case documentCapture = "live_capture"
        case documentFileUpload = "file_upload"
        case selfieCapture = "selfie"
        case success = "confirmation"
        case error = "error"
    }

    /// Name of the scanner logged in scanning performance events
    enum ScannerName: String {
        case document
        case selfie
    }

    static let sharedAnalyticsClient = AnalyticsClientV2(
        clientId: "mobile-identity-sdk",
        origin: "stripe-identity-ios"
    )

    let verificationSessionId: String
    let analyticsClient: AnalyticsClientV2Protocol

    /// Total number of times the front of the document was attempted to be scanned.
    private(set) var numDocumentFrontScanAttempts = 0

    /// Total number of times the back of the document was attempted to be scanned.
    private(set) var numDocumentBackScanAttempts = 0

    /// Total number of times a selfie was attempted to be scanned.
    private(set) var numSelfieScanAttempts = 0

    /// Tracks the start time for `timeToScreen` analytic
    private(set) var timeToScreenStartTime: Date?
    /// The last screen transitioned to for `timeToScreen` analytic
    private(set) var timeToScreenFromScreen: ScreenName?

    init(
        verificationSessionId: String,
        analyticsClient: AnalyticsClientV2Protocol = IdentityAnalyticsClient.sharedAnalyticsClient
    ) {
        self.verificationSessionId = verificationSessionId
        self.analyticsClient = analyticsClient
    }

    // MARK: - UI Events

    /// Increments the number of times a scan was initiated for the specified side of the document
    func countDidStartDocumentScan(for side: DocumentSide) {
        switch side {
        case .front:
            numDocumentFrontScanAttempts += 1
        case .back:
            numDocumentBackScanAttempts += 1
        }
    }

    /// Increments the number of times a scan was initiated for a selfie
    func countDidStartSelfieScan() {
        numSelfieScanAttempts += 1
    }

    private func logAnalytic(
        _ eventName: EventName,
        metadata: [String: Any]
    ) {
        analyticsClient.log(
            eventName: eventName.rawValue,
            parameters: [
                "verification_session": verificationSessionId,
                "event_metadata": metadata
            ]
        )
    }

    /// Logs an event when the verification sheet is presented
    func logSheetPresented() {
        logAnalytic(
            .sheetPresented,
            metadata: [:]
        )
    }

    /// Logs a closed, failed, or canceled analytic events, depending on the result
    func logSheetClosedFailedOrCanceled(
        result: IdentityVerificationSheet.VerificationFlowResult,
        sheetController: VerificationSheetControllerProtocol,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch result {
        case .flowCompleted:
            logSheetClosed(sessionResult: "flow_complete")

        case .flowCanceled:
            logVerificationCanceled(
                sheetController: sheetController
            )
            logSheetClosed(sessionResult: "flow_canceled")

        case .flowFailed(error: let error):
            logVerificationFailed(
                sheetController: sheetController,
                error: error,
                filePath: filePath,
                line: line
            )
        }
    }

    /// Helper to create metadata common to both failed, canceled, and succeed analytic events
    private func failedCanceledSucceededCommonMetadataPayload(
        sheetController: VerificationSheetControllerProtocol
    ) -> [String: Any] {
        var metadata: [String: Any] = [:]

        if let idDocumentType = sheetController.collectedData.idDocumentType {
            metadata["scan_type"] = idDocumentType.rawValue
        }
        if let verificationPage = try? sheetController.verificationPageResponse?.get() {
            metadata["require_selfie"] = verificationPage.requirements.missing.contains(.face)
            metadata["from_fallback_url"] = verificationPage.unsupportedClient
        }
        if let frontUploadMethod = sheetController.collectedData.idDocumentFront?.uploadMethod {
            metadata["doc_front_upload_type"] = frontUploadMethod.rawValue
        }
        if let backUploadMethod = sheetController.collectedData.idDocumentBack?.uploadMethod {
            metadata["doc_back_upload_type"] = backUploadMethod.rawValue
        }

        return metadata
    }

    /// Logs an event when the verification sheet is closed
    private func logSheetClosed(sessionResult: String) {
        logAnalytic(
            .sheetClosed,
            metadata: [
                "session_result": sessionResult
            ]
        )
    }

    /// Logs an event when verification sheet fails
    private func logVerificationFailed(
        sheetController: VerificationSheetControllerProtocol,
        error: Error,
        filePath: StaticString,
        line: UInt
    ) {
        var metadata = failedCanceledSucceededCommonMetadataPayload(
            sheetController: sheetController
        )
        metadata["error"] = AnalyticsClientV2.serialize(
            error: error,
            filePath: filePath,
            line: line
        )

        logAnalytic(.verificationFailed, metadata: metadata)
    }

    /// Logs an event when verification sheet is canceled
    private func logVerificationCanceled(
        sheetController: VerificationSheetControllerProtocol
    ) {
        var metadata = failedCanceledSucceededCommonMetadataPayload(
            sheetController: sheetController
        )
        if let lastScreen = sheetController.flowController.analyticsLastScreen {
            metadata["last_screen_name"] = lastScreen.analyticsScreenName.rawValue
        }

        logAnalytic(.verificationCanceled, metadata: metadata)
    }

    /// Logs an event when verification sheet succeeds
    func logVerificationSucceeded(
        sheetController: VerificationSheetControllerProtocol
    ) {
        var metadata = failedCanceledSucceededCommonMetadataPayload(
            sheetController: sheetController
        )

        metadata["doc_front_retry_times"] = max(0, numDocumentFrontScanAttempts - 1)
        metadata["doc_back_retry_times"] = max(0, numDocumentBackScanAttempts - 1)
        metadata["selfie_retry_times"] = max(0, numSelfieScanAttempts - 1)

        if let frontScore = sheetController.collectedData.frontDocumentScore {
            metadata["doc_front_model_score"] = frontScore.value
        }
        if let backScore = sheetController.collectedData.idDocumentBack?.backScore {
            metadata["doc_back_model_score"] = backScore.value
        }
        if let bestFaceScore = sheetController.collectedData.face?.bestFaceScore {
            metadata["selfie_model_score"] = bestFaceScore.value
        }

        logAnalytic(.verificationSucceeded, metadata: metadata)
    }

    /// Logs an event when a screen is presented
    func logScreenAppeared(
        screenName: ScreenName,
        sheetController: VerificationSheetControllerProtocol
    ) {
        var metadata: [String: Any] = [
            "screen_name": screenName.rawValue
        ]
        if let idDocumentType = sheetController.collectedData.idDocumentType {
            metadata["scan_type"] = idDocumentType.rawValue
        }
        logAnalytic(.screenAppeared, metadata: metadata)
    }

    /// Logs an event when a camera error occurs
    func logCameraError(
        sheetController: VerificationSheetControllerProtocol,
        error: Error,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) {
        var metadata: [String: Any] = [:]
        if let idDocumentType = sheetController.collectedData.idDocumentType {
            metadata["scan_type"] = idDocumentType.rawValue
        }
        metadata["error"] = AnalyticsClientV2.serialize(
            error: error,
            filePath: filePath,
            line: line
        )
        logAnalytic(.cameraError, metadata: metadata)
    }

    /// Logs either a permission denied or granted event when the camera permissions are checked prior to starting a camera session
    func logCameraPermissionsChecked(
        sheetController: VerificationSheetControllerProtocol,
        isGranted: Bool?
    ) {
        var metadata: [String: Any] = [:]
        if let idDocumentType = sheetController.collectedData.idDocumentType {
            metadata["scan_type"] = idDocumentType.rawValue
        }

        let eventName: EventName = (isGranted == true) ? .cameraPermissionGranted : .cameraPermissionDenied

        logAnalytic(eventName, metadata: metadata)
    }

    /// Logs an event when document capture times out
    func logDocumentCaptureTimeout(
        idDocumentType: DocumentType,
        documentSide: DocumentSide
    ) {
        logAnalytic(.documentCaptureTimeout, metadata: [
            "scan_type": idDocumentType.rawValue,
            "side": documentSide.rawValue
        ])
    }

    /// Logs an event when selfie capture times out
    func logSelfieCaptureTimeout() {
        logAnalytic(.selfieCaptureTimeout, metadata: [:])
    }

    // MARK: - Performance Events

    /// Logs the a scan's average number of frames per seconds processed
    func logAverageFramesPerSecond(
        averageFPS: Double,
        numFrames: Int,
        scannerName: ScannerName
    ) {
        logAnalytic(.averageFPS, metadata: [
            "type": scannerName.rawValue,
            "value": averageFPS,
            "frames": numFrames
        ])
    }

    /// Logs the average inference and post-processing times for every ML model used for one scan
    func logModelPerformance(
        mlModelMetricsTrackers: [MLDetectorMetricsTrackerProtocol]
    ) {
        mlModelMetricsTrackers.forEach { metricsTracker in
            // Cache values to avoid weakly capturing performanceTracker
            let modelName = metricsTracker.modelName

            metricsTracker.getPerformanceMetrics(completeOn: .main) { averageMetrics, numFrames in
                guard numFrames > 0 else { return }
                self.logModelPerformance(
                    modelName: modelName,
                    averageMetrics: averageMetrics,
                    numFrames: numFrames
                )
            }
        }
    }

    /// Logs an ML model's average inference and post-process time during a scan
    private func logModelPerformance(
        modelName: String,
        averageMetrics: MLDetectorMetricsTracker.Metrics,
        numFrames: Int
    ) {
        logAnalytic(.modelPerformance, metadata: [
            "ml_model": modelName,
            "inference": averageMetrics.inference.milliseconds,
            "postprocess": averageMetrics.postProcess.milliseconds,
            "frames": numFrames,
        ])
    }

    /// Logs the time it takes to upload an image along with its file size and compression quality
    func logImageUpload(
        idDocumentType: DocumentType?,
        timeToUpload: TimeInterval,
        compressionQuality: CGFloat,
        fileId: String,
        fileName: String,
        fileSizeBytes: Int
    ) {
        // NOTE: File size is logged in kB
        var metadata: [String: Any] = [
            "value": timeToUpload.milliseconds,
            "id": fileId,
            "compression_quality": compressionQuality,
            "file_name": fileName,
            "file_size": fileSizeBytes / 1024
        ]
        if let idDocumentType = idDocumentType {
            metadata["scan_type"] = idDocumentType.rawValue
        }

        logAnalytic(.imageUpload, metadata: metadata)
    }

    /// Tracks the time when a user taps a button to continue to the next screen.
    /// Should be followed by a call to `stopTrackingTimeToScreenAndLogIfNeeded`
    /// when the next screen appears.
    func startTrackingTimeToScreen(
        from fromScreen: ScreenName?
    ) {
        if timeToScreenStartTime != nil {
            logGenericError(
                error: IdentityAnalyticsClientError.timeToScreenAlreadyStarted(
                    alreadyStartedForScreen: timeToScreenFromScreen,
                    requestedForScreen: fromScreen
                )
            )
        }
        timeToScreenStartTime = Date()
        timeToScreenFromScreen = fromScreen
    }

    /// Logs the time it takes for a screen to appear after the user takes an
    /// action to proceed to the next screen in the flow.
    /// If `startTrackingTimeToScreen` was not called before calling this method,
    /// an analytic is not logged.
    func stopTrackingTimeToScreenAndLogIfNeeded(to toScreen: ScreenName) {
        let endTime = Date()

        defer {
            // Reset state properties
            self.timeToScreenStartTime = nil
            self.timeToScreenFromScreen = nil
        }

        // This method could be called unnecessarily from `viewDidAppear` in the
        // case that the view controller was presenting another screen that was
        // dismissed or the back button was used. Only log an analytic if there's
        // `startTrackingTimeToScreen` was called.
        guard let startTime = timeToScreenStartTime,
              timeToScreenFromScreen != toScreen
        else {
            return
        }

        var metadata: [String: Any] = [
            "value": endTime.timeIntervalSince(startTime).milliseconds,
            "to_screen_name": toScreen.rawValue
        ]
        if let fromScreen = timeToScreenFromScreen {
            metadata["from_screen_name"] = fromScreen.rawValue
        }

        logAnalytic(.timeToScreen, metadata: metadata)
    }

    // MARK: - Error Events

    /// Logs when an error occurs.
    func logGenericError(
        error: Error,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) {
        logAnalytic(.genericError, metadata: [
            "error_details": AnalyticsClientV2.serialize(
                error: error,
                filePath: filePath,
                line: line
            )
        ])
    }
}
