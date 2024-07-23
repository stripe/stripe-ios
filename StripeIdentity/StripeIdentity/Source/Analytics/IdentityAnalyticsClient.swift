//
//  IdentityAnalyticsClient.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

enum IdentityAnalyticsClientError: AnalyticLoggableErrorV2 {
    /// `startTrackingTimeToScreen` was called twice in a row without calling
    /// `stopTrackingTimeToScreenAndLogIfNeeded`
    case timeToScreenAlreadyStarted(
        alreadyStartedForScreen: IdentityAnalyticsClient.ScreenName?,
        requestedForScreen: IdentityAnalyticsClient.ScreenName?
    )

    func analyticLoggableSerializeForLogging() -> [String: Any] {
        var payload: [String: Any] = [
            "domain": (self as NSError).domain,
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
        // MARK: Experiment
        case experimentExposure = "preloaded_experiment_retrieved"
    }

    enum ScreenName: String {
        case biometricConsent = "consent"
        case documentCapture = "live_capture"
        case documentFileUpload = "file_upload"
        case documentWarmup = "document_warmup"
        case selfieCapture = "selfie"
        case selfieWarmup = "selfie_warmup"
        case success = "confirmation"
        case individual = "individual"
        case phoneOtp = "phone_otp"
        case individual_welcome = "individual_welcome"
        case error = "error"
        case countryNotListed = "country_not_listed"
        case debug = "debug"
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

    private(set) var blurScoreFront: Float?
    private(set) var blurScoreBack: Float?

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

    func updateBlurScore(_ blurScore: Float, for side: DocumentSide) {
        if side == .front {
            blurScoreFront = blurScore
        } else {
            blurScoreBack = blurScore
        }
    }

    private func logAnalytic(
        _ eventName: EventName,
        metadata: [String: Any],
        verificationPage: StripeAPI.VerificationPage?
    ) {
        if let verificationPage = verificationPage {
            let userSessionId = verificationPage.userSessionId
            let experiments = verificationPage.experiments

            for exp in experiments {
                if exp.eventName == eventName.rawValue &&
                    (exp.eventMetadata.allSatisfy { (key, value) in
                        return metadata[key] as? String == value
                    }) {
                    analyticsClient.log(
                        eventName: EventName.experimentExposure.rawValue,
                        parameters: [
                            "arb_id": userSessionId,
                            "experiment_retrieved": exp.experimentName,
                        ]
                    )
                }
            }
        }

        analyticsClient.log(
            eventName: eventName.rawValue,
            parameters: [
                "verification_session": verificationSessionId,
                "event_metadata": metadata,
            ]
        )
    }

    /// Logs an event when the verification sheet is presented
    func logSheetPresented(sheetController: VerificationSheetControllerProtocol) {
        logAnalytic(
            .sheetPresented,
            metadata: [:],
            verificationPage: try? sheetController.verificationPageResponse?.get()
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
            logSheetClosed(
                sessionResult: "flow_complete",
                sheetController: sheetController
            )

        case .flowCanceled:
            logVerificationCanceled(
                sheetController: sheetController
            )
            logSheetClosed(
                sessionResult: "flow_canceled",
                sheetController: sheetController
            )

        case .flowFailed(let error):
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
    private func logSheetClosed(sessionResult: String, sheetController: VerificationSheetControllerProtocol) {
        logAnalytic(
            .sheetClosed,
            metadata: [
                "session_result": sessionResult
            ],
            verificationPage: try? sheetController.verificationPageResponse?.get()
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

        logAnalytic(.verificationFailed, metadata: metadata, verificationPage: try? sheetController.verificationPageResponse?.get())
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

        logAnalytic(.verificationCanceled, metadata: metadata, verificationPage: try? sheetController.verificationPageResponse?.get())
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
        if let blurScoreFront = blurScoreFront {
            metadata["doc_front_blur_score"] = blurScoreFront
        }
        if let blurScoreBack = blurScoreBack {
            metadata["doc_back_blur_score"] = blurScoreBack
        }

        logAnalytic(.verificationSucceeded, metadata: metadata, verificationPage: try? sheetController.verificationPageResponse?.get())
    }

    /// Logs an event when a screen is presented
    func logScreenAppeared(
        screenName: ScreenName,
        sheetController: VerificationSheetControllerProtocol
    ) {
        let metadata: [String: Any] = [
            "screen_name": screenName.rawValue,
        ]

        logAnalytic(.screenAppeared, metadata: metadata, verificationPage: try? sheetController.verificationPageResponse?.get())
    }

    /// Logs an event when a camera error occurs
    func logCameraError(
        sheetController: VerificationSheetControllerProtocol,
        error: Error,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) {
        var metadata: [String: Any] = [:]
        metadata["error"] = AnalyticsClientV2.serialize(
            error: error,
            filePath: filePath,
            line: line
        )
        logAnalytic(.cameraError, metadata: metadata, verificationPage: try? sheetController.verificationPageResponse?.get())
    }

    /// Logs either a permission denied or granted event when the camera permissions are checked prior to starting a camera session
    func logCameraPermissionsChecked(
        sheetController: VerificationSheetControllerProtocol,
        isGranted: Bool?
    ) {
        let eventName: EventName =
            (isGranted == true) ? .cameraPermissionGranted : .cameraPermissionDenied

        logAnalytic(eventName, metadata: [:], verificationPage: try? sheetController.verificationPageResponse?.get())
    }

    /// Logs an event when document capture times out
    func logDocumentCaptureTimeout(
        documentSide: DocumentSide,
        sheetController: VerificationSheetControllerProtocol
    ) {
        logAnalytic(
            .documentCaptureTimeout,
            metadata: [
                "side": documentSide.rawValue,
            ],
            verificationPage: try? sheetController.verificationPageResponse?.get()
        )
    }

    /// Logs an event when selfie capture times out
    func logSelfieCaptureTimeout(sheetController: VerificationSheetControllerProtocol) {
        logAnalytic(.selfieCaptureTimeout, metadata: [:], verificationPage: try? sheetController.verificationPageResponse?.get())
    }

    // MARK: - Performance Events

    /// Logs the a scan's average number of frames per seconds processed
    func logAverageFramesPerSecond(
        averageFPS: Double,
        numFrames: Int,
        scannerName: ScannerName,
        sheetController: VerificationSheetControllerProtocol
    ) {
        logAnalytic(
            .averageFPS,
            metadata: [
                "type": scannerName.rawValue,
                "value": averageFPS,
                "frames": numFrames,
            ],
            verificationPage: try? sheetController.verificationPageResponse?.get()
        )
    }

    /// Logs the average inference and post-processing times for every ML model used for one scan
    func logModelPerformance(
        mlModelMetricsTrackers: [MLDetectorMetricsTrackerProtocol],
        sheetController: VerificationSheetControllerProtocol
    ) {
        mlModelMetricsTrackers.forEach { metricsTracker in
            // Cache values to avoid weakly capturing performanceTracker
            let modelName = metricsTracker.modelName

            metricsTracker.getPerformanceMetrics(completeOn: .main) { averageMetrics, numFrames in
                guard numFrames > 0 else { return }
                self.logModelPerformance(
                    modelName: modelName,
                    averageMetrics: averageMetrics,
                    numFrames: numFrames,
                    sheetController: sheetController
                )
            }
        }
    }

    /// Logs an ML model's average inference and post-process time during a scan
    private func logModelPerformance(
        modelName: String,
        averageMetrics: MLDetectorMetricsTracker.Metrics,
        numFrames: Int,
        sheetController: VerificationSheetControllerProtocol
    ) {
        logAnalytic(
            .modelPerformance,
            metadata: [
                "ml_model": modelName,
                "inference": averageMetrics.inference.milliseconds,
                "postprocess": averageMetrics.postProcess.milliseconds,
                "frames": numFrames,
            ],
            verificationPage: try? sheetController.verificationPageResponse?.get()
        )
    }

    /// Logs the time it takes to upload an image along with its file size and compression quality
    func logImageUpload(
        timeToUpload: TimeInterval,
        compressionQuality: CGFloat,
        fileId: String,
        fileName: String,
        fileSizeBytes: Int,
        sheetController: VerificationSheetControllerProtocol
    ) {
        // NOTE: File size is logged in kB
        let metadata: [String: Any] = [
            "value": timeToUpload.milliseconds,
            "id": fileId,
            "compression_quality": compressionQuality,
            "file_name": fileName,
            "file_size": fileSizeBytes / 1024,
        ]

        logAnalytic(.imageUpload, metadata: metadata, verificationPage: try? sheetController.verificationPageResponse?.get())
    }

    /// Tracks the time when a user taps a button to continue to the next screen.
    /// Should be followed by a call to `stopTrackingTimeToScreenAndLogIfNeeded`
    /// when the next screen appears.
    func startTrackingTimeToScreen(
        from fromScreen: ScreenName?,
        sheetController: VerificationSheetControllerProtocol
    ) {
        if timeToScreenStartTime != nil {
            logGenericError(
                error: IdentityAnalyticsClientError.timeToScreenAlreadyStarted(
                    alreadyStartedForScreen: timeToScreenFromScreen,
                    requestedForScreen: fromScreen
                ),
                sheetController: sheetController
            )
        }
        timeToScreenStartTime = Date()
        timeToScreenFromScreen = fromScreen
    }

    /// Logs the time it takes for a screen to appear after the user takes an
    /// action to proceed to the next screen in the flow.
    /// If `startTrackingTimeToScreen` was not called before calling this method,
    /// an analytic is not logged.
    func stopTrackingTimeToScreenAndLogIfNeeded(
        to toScreen: ScreenName,
        sheetController: VerificationSheetControllerProtocol
    ) {
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
            "to_screen_name": toScreen.rawValue,
        ]
        if let fromScreen = timeToScreenFromScreen {
            metadata["from_screen_name"] = fromScreen.rawValue
        }

        logAnalytic(.timeToScreen, metadata: metadata, verificationPage: try? sheetController.verificationPageResponse?.get())
    }

    // MARK: - Error Events

    /// Logs when an error occurs.
    func logGenericError(
        error: Error,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        sheetController: VerificationSheetControllerProtocol
    ) {
        logAnalytic(
            .genericError,
            metadata: [
                "error_details": AnalyticsClientV2.serialize(
                    error: error,
                    filePath: filePath,
                    line: line
                ),
            ],
            verificationPage: try? sheetController.verificationPageResponse?.get()
        )
    }
}
