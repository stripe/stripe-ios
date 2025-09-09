//
//  FaceScanner.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreVideo
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
import Vision

typealias AnyFaceScanner = AnyImageScanner<FaceScannerOutput>

final class FaceScanner {

    private let faceDetector: FaceDetector
    private let configuration: Configuration

    init(
        faceDetector: FaceDetector,
        configuration: Configuration
    ) {
        self.faceDetector = faceDetector
        self.configuration = configuration
    }

    convenience init(
        faceDetectorModel: VNCoreMLModel,
        configuration: Configuration
    ) {
        self.init(
            faceDetector: .init(
                model: faceDetectorModel,
                configuration: .init(
                    minScore: configuration.faceDetectorMinScore,
                    minIOU: configuration.faceDetectorMinIOU
                )
            ),
            configuration: configuration
        )
    }
}

extension FaceScanner: ImageScanner {
    typealias Output = FaceScannerOutput

    var mlModelMetricsTrackers: [MLDetectorMetricsTrackerProtocol] {
        return [faceDetector].compactMap { $0.metricsTracker }
    }

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        sampleBuffer: CMSampleBuffer,
        cameraProperties: CameraSession.DeviceProperties?
    ) -> StripeCore.Future<FaceScannerOutput> {
        do {
            return Promise(
                value: .init(
                    faceDetectorOutput: try faceDetector.scanImage(
                        pixelBuffer: pixelBuffer
                    ),
                    cameraProperties: cameraProperties,
                    configuration: configuration
                )
            )
        } catch {
            return Promise(error: error)
        }

    }

    func reset() {
        faceDetector.metricsTracker?.reset()
    }
}
