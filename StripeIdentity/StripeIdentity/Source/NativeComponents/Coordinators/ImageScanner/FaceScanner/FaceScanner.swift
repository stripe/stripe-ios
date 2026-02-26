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
    private let blurDetector: LaplacianBlurDetector?

    init(
        faceDetector: FaceDetector,
        configuration: Configuration
    ) {
        self.faceDetector = faceDetector
        self.configuration = configuration
        self.blurDetector = configuration.blurThreshold
            .flatMap { $0 > 0 ? LaplacianBlurDetector(blurThreshold: $0) : nil }
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
            let faceDetectorOutput = try faceDetector.scanImage(pixelBuffer: pixelBuffer)
            return Promise(
                value: .init(
                    faceDetectorOutput: faceDetectorOutput,
                    cameraProperties: cameraProperties,
                    configuration: configuration,
                    blurResult: blurResult(
                        for: pixelBuffer,
                        faceDetectorOutput: faceDetectorOutput
                    )
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

extension FaceScanner {
    fileprivate func blurResult(
        for pixelBuffer: CVPixelBuffer,
        faceDetectorOutput: FaceDetectorOutput
    ) -> LaplacianBlurDetector.Output? {
        guard
            let blurDetector = blurDetector,
            faceDetectorOutput.predictions.count == 1,
            let faceRect = faceDetectorOutput.predictions.first?.rect,
            let originalImage = pixelBuffer.cgImage(),
            let croppedImage = try? originalImage.cropping(
                toNormalizedRegion: faceRect,
                withPadding: 0,
                computationMethod: .regionWidth
            )
        else {
            return nil
        }

        return blurDetector.calculateBlurOutput(inputImage: croppedImage)
    }
}
