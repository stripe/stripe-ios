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


    func imageScanningSessionShouldScanCameraOutput(_ scanningSession: ScanningSession) -> Bool

    func imageScanningSessionDidUpdate(_ scanningSession: ScanningSession)

    func imageScanningSessionDidReset(_ scanningSession: ScanningSession)

    func imageScanningSessionWillStartScanning(_ scanningSession: ScanningSession)

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

        let shouldScanCameraOutput: (
            _ scanningSession: ScanningSession
        ) -> Bool?

        let didUpdate: (
            _ scanningSession: ScanningSession
        ) -> Void

        let didReset: (
            _ scanningSession: ScanningSession
        ) -> Void

        let willStartScanning: (
            _ scanningSession: ScanningSession
        ) -> Void

        let didStopScanning: (
            _ scanningSession: ScanningSession
        ) -> Void

        let didScanImage: (
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

            shouldScanCameraOutput = { [weak delegate] scanningSession in
                delegate?.imageScanningSessionShouldScanCameraOutput(scanningSession)
            }

            didUpdate = { [weak delegate] scanningSession in
                delegate?.imageScanningSessionDidUpdate(scanningSession)
            }

            didReset = { [weak delegate] scanningSession in
                delegate?.imageScanningSessionDidReset(scanningSession)
            }

            willStartScanning = { [weak delegate] scanningSession in
                delegate?.imageScanningSessionWillStartScanning(scanningSession)
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

        func imageScanningSessionShouldScanCameraOutput(_ scanningSession: ScanningSession) -> Bool? {
            return shouldScanCameraOutput(scanningSession)
        }

        func imageScanningSessionDidUpdate(_ scanningSession: ScanningSession) {
            didUpdate(scanningSession)
        }

        func imageScanningSessionDidReset(_ scanningSession: ScanningSession) {
            didReset(scanningSession)
        }

        func imageScanningSessionWillStartScanning(_ scanningSession: ScanningSession) {
            willStartScanning(scanningSession)
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
