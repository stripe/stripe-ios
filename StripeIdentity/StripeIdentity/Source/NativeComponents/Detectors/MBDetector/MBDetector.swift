//
//  MBDetector.swift
//  StripeIdentity
//
//  Created by Chen Cen on 1/9/24.
//

import CaptureCore
import Foundation
@_spi(STP) import StripeCore

final class MBDetector: NSObject {

    public init(mbSettings: StripeAPI.VerificationPageStaticContentDocumentCaptureMBSettings) throws {
        super.init()
        try setupLicense(licenseKey: mbSettings.licenseKey)
        MBCCAnalyzerRunner.shared().settings = mbSettings.toMBCCAnalyzerSettings()
        MBCCAnalyzerRunner.shared().delegate = MBDelegate.shared
    }

    fileprivate func setupLicense(licenseKey: String) throws {
        let initializationSemaphore = DispatchSemaphore(value: 0)
        var initializationError: MBCCLicenseError?
        MBCCCaptureCoreSDK.shared().setLicenseKey(licenseKey) { error in
            initializationError = error
            initializationSemaphore.signal()
        }

        _ = initializationSemaphore.wait(timeout: .now().advanced(by: .milliseconds(1_000)))

        if let initializationError {
            switch initializationError {
            case .networkRequired:
                throw MBDetectorError.incorrectLicense("network required")
            case .unableToDoRemoteLicenceCheck:
                throw MBDetectorError.incorrectLicense("unable to do remote license check")
            case .licenseIsLocked:
                throw MBDetectorError.incorrectLicense("license is locked")
            case .licenseCheckFailed:
                throw MBDetectorError.incorrectLicense("license check failed")
            case .invalidLicense:
                throw MBDetectorError.incorrectLicense("invalid license")
            case .permissionExpired:
                throw MBDetectorError.incorrectLicense("permission expired")
            case .payloadCorrupted:
                throw MBDetectorError.incorrectLicense("payload corrupted")
            case .payloadSignatureVerificationFailed:
                throw MBDetectorError.incorrectLicense("payload signature verification failed")
            case .incorrectTokenState:
                throw MBDetectorError.incorrectLicense("incorrect token state")
            @unknown default:
                throw MBDetectorError.incorrectLicense("unkonwn error")
            }
        }
    }

    func analyze(sampleBuffer: CMSampleBuffer) -> Future<MBDetector.DetectorResult> {
        let promise = Promise<MBDetector.DetectorResult>()
        let image = MBCCSampleBufferImage(sampleBuffer: sampleBuffer)

        image.imageOrientation = .right
        image.videoRotationAngle = .portrait

        MBCCAnalyzerRunner.shared().analyzeStreamImage(image)
        MBDelegate.shared.onResult = { analysisResult in
            promise.resolve(with: analysisResult.toDetectorResult())
        }
        MBDelegate.shared.onError = { error in
            promise.resolve(with: .error(.runnerError(error)))
        }
        return promise
    }

    func reset() {
        MBCCAnalyzerRunner.shared().reset()
    }
}

private class MBDelegate: NSObject, MBCCAnalyzerRunnerDelegate {
    // The delegate will be set multiple times if hosting app invokes the SDK more than once.
    // Holding a static reference to avoid a deinit error from MBCCAnalyzerRunner.shared().delegate.
    static var shared: MBDelegate = MBDelegate()

    private override init() {
        super.init()
    }

    var onResult: ((MBCCFrameAnalysisResult) -> Void)?

    var onError: ((MBCCAnalyzerRunnerError) -> Void)?

    func analyzerRunner(_ analyzerRunner: MBCCAnalyzerRunner, didAnalyzeFrameWith frameAnalysisResult: MBCCFrameAnalysisResult) {
        if let onResult = self.onResult {
              onResult(frameAnalysisResult)
        }
    }

    func analyzerRunner(_ analyzerRunner: MBCCAnalyzerRunner, didFailWithAnalyzerError analyzerError: MBCCAnalyzerRunnerError) {
        if let onError = self.onError {
            onError(analyzerError)
        }
    }

}

extension MBDetector {
    enum DetectorResult: Equatable {
        case captured(UIImage, UIImage, DocumentSide) // original, transformed, side
        case capturing(CaptureFeedback)
        case error(MBDetectorError)
    }

    enum CaptureFeedback {
        case documentFramingNoDocument
        case documentFramingCameraTooFar
        case documentFramingCameraTooClose
        case documentFramingCameraAngleTooSteep
        case documentFramingCameraOrientationUnsuitable
        case documentTooCloseToFrameEdge
        case lightingTooDark
        case lightingTooBright
        case blurDetected
        case glareDetected
        case occludedByHand
        case wrongSide
        case unknown
    }

    enum MBDetectorError: Error, Equatable {
        case incorrectLicense(String)
        case unexpectedSideCaptured
        case noValidResult
        case capturedSecondSide
        case runnerError(MBCCAnalyzerRunnerError)
        case unknown
    }

}

extension MBDetector.CaptureFeedback {
    func getFeedbackMessage() -> String {
        switch self {
        case .documentFramingCameraOrientationUnsuitable:
            return String.Localized.rotate_document

        case .documentFramingCameraTooFar:
            return String.Localized.move_closer

        case .documentFramingCameraTooClose, .documentTooCloseToFrameEdge:
            return String.Localized.move_farther

        case .documentFramingCameraAngleTooSteep:
            return String.Localized.align_document

        case .lightingTooDark:
            return String.Localized.increase_lighting

        case .lightingTooBright:
            return String.Localized.decrease_lighting

        case .blurDetected:
            return String.Localized.reduce_blur

        case .glareDetected:
            return String.Localized.reduce_glare

        case .occludedByHand:
            return String.Localized.keep_fully_visibile

        case .wrongSide:
            return String.Localized.flip_to_other_side

        case .documentFramingNoDocument:
            return String.Localized.point_camera_to_document
        case .unknown:
            return ""
        }
    }
}

extension StripeAPI.MBCaptureStrategyType {
    func toMBCCCaptureStrategy() -> MBCCCaptureStrategy {
        switch self {
        case .singleFrame:
            return .singleFrame
        case .optimizeForQuality:
            return .optimizeForQuality
        case .optimizeForSpeed:
            return .optimizeForSpeed
        case .defaultValue:
            return .default
        }
    }
}

extension StripeAPI.MBTiltPolicyType {
    func toMBCCTiltPolicy() -> MBCCTiltPolicy {
        switch self {
        case .disabled:
            return .disabled
        case .normal:
            return .normal
        case .relaxed:
            return .relaxed
        case .strict:
            return .strict
        }
    }
}

extension StripeAPI.MBBlurPolicyType {
    func toMBCCBlurPolicy() -> MBCCBlurPolicy {
        switch self {
        case .disabled:
            return .disabled
        case .normal:
            return .normal
        case .relaxed:
            return .relaxed
        case .strict:
            return .strict
        }
    }
}

extension StripeAPI.MBGlarePolicyType {
    func toMBCCGlarePolicy() -> MBCCGlarePolicy {
        switch self {
        case .disabled:
            return .disabled
        case .normal:
            return .normal
        case .relaxed:
            return .relaxed
        case .strict:
            return .strict
        }
    }
}

extension MBDetector.MBDetectorError: AnalyticLoggableErrorV2 {
    func analyticLoggableSerializeForLogging() -> [String: Any] {
        var payload: [String: Any]
        switch self {
        case .incorrectLicense(let reason):
            payload = [
                "type": "incorrect_license",
                "reason": reason,
            ]
        case .unexpectedSideCaptured:
            payload = [
                "type": "unexpected_side_captured"
            ]
        case .noValidResult:
            payload = [
                "type": "no_valid_result"
            ]
        case .capturedSecondSide:
            payload = [
                "type": "captured_second_side"
            ]
        case .runnerError(let mbRunnerError):
            payload = [
                "type": "analyzer_runner_error"
            ]
            switch mbRunnerError {
            case .invalidLicenseKey:
                payload["runner_error"] = "invalid_license_key"
            case .licenseLocked:
                payload["runner_error"] = "license_locked"
            case .unableToActivateOnlineLicense:
                payload["runner_error"] = "unable_to_active_online_license"
            case .memoryReserveFailure:
                payload["runner_error"] = "memory_reserve_failure"
            case .missingResources:
                payload["runner_error"] = "missing_resources"
            case .analyzerSettingsUnsuitable:
                payload["runner_error"] = "analyzer_settings_unsuitable"
            @unknown default:
                payload["runner_error"] = "default"
            }
        case .unknown:
            payload = [
                "type": "unknown"
            ]
        }
        return payload
    }
}

extension StripeAPI.VerificationPageStaticContentDocumentCaptureMBSettings {
    func toMBCCAnalyzerSettings() -> MBCCAnalyzerSettings {
        let settings = MBCCAnalyzerSettings()
        // Always capture single side
        settings.captureSingleSide = true
        settings.returnTransformedDocumentImage = self.returnTransformedDocumentImage
        settings.keepMarginOnTransformedDocumentImage = self.keepMarginOnTransformedDocumentImage
        settings.documentFramingMargin = self.documentFramingMargin
        settings.handOcclusionThreshold = self.handOcclusionThreshold
        settings.captureStrategy = self.captureStrategy.toMBCCCaptureStrategy()
        settings.lightingThresholds = .init(
            tooDarkTreshold: self.tooBrightThreshold,
            tooBrightThreshold: self.tooBrightThreshold
        )
        settings.minimumDocumentDpi = self.minimumDocumentDpi
        settings.adjustMinimumDocumentDpi = self.adjustMinimumDocumentDpi
        settings.tiltPolicy = self.tiltPolicy.toMBCCTiltPolicy()
        settings.blurPolicy = self.blurPolicy.toMBCCBlurPolicy()
        settings.glarePolicy = self.glarePolicy.toMBCCGlarePolicy()
        return settings
    }
}
