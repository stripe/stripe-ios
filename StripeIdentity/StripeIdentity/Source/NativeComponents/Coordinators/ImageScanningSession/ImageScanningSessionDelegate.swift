//
//  ImageScanningSessionDelegate.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/9/22.
//

import Foundation
import AVKit
@_spi(STP) import StripeCameraCore

@available(iOSApplicationExtension, unavailable)
protocol ImageScanningSessionDelegate: AnyObject {

    associatedtype ExpectedClassificationType: Equatable
    associatedtype ScanningStateType: Equatable & ScanningState
    associatedtype CapturedDataType: Equatable
    associatedtype ScannerOutput

    typealias ScanningSession = ImageScanningSession<
        ExpectedClassificationType,
        ScanningStateType,
        CapturedDataType,
        ScannerOutput
    >

    func imageScanningSession(
        _ scanningSession: ScanningSession,
        cameraDidError: Error
    )

    func imageScanningSession(
        _ scanningSession: ScanningSession,
        didRequestCameraAccess isGranted: Bool?
    )

    func imageScanningSessionShouldScanCameraOutput(_ scanningSession: ScanningSession) -> Bool

    func imageScanningSessionDidUpdate(_ scanningSession: ScanningSession)

    func imageScanningSessionDidReset(_ scanningSession: ScanningSession)

    func imageScanningSession(
        _ scanningSession: ScanningSession,
        didTimeoutForClassification classification: ExpectedClassificationType
    )

    func imageScanningSession(
        _ scanningSession: ScanningSession,
        willStartScanningForClassification classification: ExpectedClassificationType
    )

    func imageScanningSessionWillStopScanning(_ scanningSession: ScanningSession)

    func imageScanningSessionDidStopScanning(_ scanningSession: ScanningSession)

    func imageScanningSessionDidScanImage(
        _ scanningSession: ScanningSession,
        image: CGImage,
        scannerOutput: ScannerOutput,
        exifMetadata: CameraExifMetadata?,
        expectedClassification: ExpectedClassificationType
    )
}

// MARK: - Default Implementation

@available(iOSApplicationExtension, unavailable)
extension ImageScanningSessionDelegate {
    func imageScanningSessionShouldScanCameraOutput(_ scanningSession: ScanningSession) -> Bool {
        return true
    }
}

// MARK: - AnyDelegate

@available(iOSApplicationExtension, unavailable)
extension ImageScanningSession {
    /// Type-erased ImageScanningSessionDelegate
    struct AnyDelegate {
        typealias ScanningSession = ImageScanningSession

        private let cameraDidError: (
            _ scanningSession: ScanningSession,
            _ cameraError: Error
        ) -> Void

        private let didRequestCameraAccess: (
            _ scanningSession: ScanningSession,
            _ isGranted: Bool?
        ) -> Void

        private let shouldScanCameraOutput: (
            _ scanningSession: ScanningSession
        ) -> Bool?

        private let didUpdate: (
            _ scanningSession: ScanningSession
        ) -> Void

        private let didReset: (
            _ scanningSession: ScanningSession
        ) -> Void

        private let didTimeout: (
            _ scanningSession: ScanningSession,
            _ classification: ExpectedClassificationType
        ) -> Void

        private let willStartScanning: (
            _ scanningSession: ScanningSession,
            _ classification: ExpectedClassificationType
        ) -> Void

        private let willStopScanning: (
            _ scanningSession: ScanningSession
        ) -> Void

        private let didStopScanning: (
            _ scanningSession: ScanningSession
        ) -> Void

        private let didScanImage: (
            _ scanningSession: ScanningSession,
            _ image: CGImage,
            _ scannerOutput: ScannerOutput,
            _ exifMetadata: CameraExifMetadata?,
            _ expectedClassification: ExpectedClassificationType
        ) -> Void

        init<Delegate: ImageScanningSessionDelegate>(
            _ delegate: Delegate
        ) where Delegate.ExpectedClassificationType == ExpectedClassificationType,
                Delegate.ScanningStateType == ScanningStateType,
                Delegate.CapturedDataType == CapturedDataType,
                Delegate.ScannerOutput == ScannerOutput
        {
            // NOTE: All closures must keep a weak reference to delegate

            cameraDidError = { [weak delegate] scanningSession, cameraError in
                delegate?.imageScanningSession(scanningSession, cameraDidError: cameraError)
            }

            didRequestCameraAccess = { [weak delegate] scanningSession, isGranted in
                delegate?.imageScanningSession(scanningSession, didRequestCameraAccess: isGranted)
            }

            shouldScanCameraOutput = { [weak delegate] scanningSession in
                delegate?.imageScanningSessionShouldScanCameraOutput(scanningSession)
            }

            didUpdate = { [weak delegate] scanningSession in
                delegate?.imageScanningSessionDidUpdate(scanningSession)
            }

            didReset = { [weak delegate] scanningSession in
                delegate?.imageScanningSessionDidReset(scanningSession)
            }

            didTimeout = { [weak delegate] scanningSession, classification in
                delegate?.imageScanningSession(scanningSession, didTimeoutForClassification: classification)
            }

            willStartScanning = { [weak delegate] scanningSession, classification in
                delegate?.imageScanningSession(scanningSession, willStartScanningForClassification: classification)
            }

            willStopScanning = { [weak delegate] scanningSession in
                delegate?.imageScanningSessionWillStopScanning(scanningSession)
            }

            didStopScanning = { [weak delegate] scanningSession in
                delegate?.imageScanningSessionDidStopScanning(scanningSession)
            }

            didScanImage = { [weak delegate] scanningSession, image, scannerOutput, exifMetadata, expectedClassification in

                delegate?.imageScanningSessionDidScanImage(
                    scanningSession,
                    image: image,
                    scannerOutput: scannerOutput,
                    exifMetadata: exifMetadata,
                    expectedClassification: expectedClassification
                )
            }
        }

        func imageScanningSession(
            _ scanningSession: ScanningSession,
            cameraDidError error: Error
        ) {
            cameraDidError(scanningSession, error)
        }

        func imageScanningSession(
            _ scanningSession: ScanningSession,
            didRequestCameraAccess isGranted: Bool?
        ) {
            didRequestCameraAccess(scanningSession, isGranted)
        }

        func imageScanningSessionShouldScanCameraOutput(_ scanningSession: ScanningSession) -> Bool? {
            return shouldScanCameraOutput(scanningSession)
        }

        func imageScanningSessionDidUpdate(_ scanningSession: ScanningSession) {
            didUpdate(scanningSession)
        }

        func imageScanningSessionDidReset(_ scanningSession: ScanningSession) {
            didReset(scanningSession)
        }

        func imageScanningSession(
            _ scanningSession: ScanningSession,
            didTimeoutForClassification classification: ExpectedClassificationType
        ) {
            didTimeout(scanningSession, classification)
        }
        
        func imageScanningSession(
            _ scanningSession: ScanningSession,
            willStartScanningForClassification classification: ExpectedClassificationType
        ) {
            willStartScanning(scanningSession, classification)
        }

        func imageScanningSessionWillStopScanning(_ scanningSession: ScanningSession) {
            willStopScanning(scanningSession)
        }

        func imageScanningSessionDidStopScanning(_ scanningSession: ScanningSession) {
            didStopScanning(scanningSession)
        }

        func imageScanningSessionDidScanImage(
            _ scanningSession: ScanningSession,
            image: CGImage,
            scannerOutput: ScannerOutput,
            exifMetadata: CameraExifMetadata?,
            expectedClassification: ExpectedClassificationType
        ) {
            didScanImage(
                scanningSession,
                image,
                scannerOutput,
                exifMetadata,
                expectedClassification
            )
        }
    }
}
