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
    private enum MotionBlurGate {
        static let minIOU: Float = 0.94
        static let minDuration: Double = 0.1
    }

    private let faceDetector: FaceDetector
    private let facePoseDetector: FacePoseDetector?
    private let configuration: Configuration
    private let motionBlurDetector: MotionBlurDetector

    init(
        faceDetector: FaceDetector,
        facePoseDetector: FacePoseDetector? = nil,
        configuration: Configuration
    ) {
        self.faceDetector = faceDetector
        self.facePoseDetector = facePoseDetector
        self.configuration = configuration
        self.motionBlurDetector = MotionBlurDetector(
            minIOU: MotionBlurGate.minIOU,
            minTime: MotionBlurGate.minDuration
        )
    }

    convenience init(
        faceDetectorModel: VNCoreMLModel,
        configuration: Configuration,
        facePoseDetector: FacePoseDetector? = nil
    ) {
        self.init(
            faceDetector: .init(
                model: faceDetectorModel,
                configuration: .init(
                    minScore: configuration.faceDetectorMinScore,
                    minIOU: configuration.faceDetectorMinIOU
                )
            ),
            facePoseDetector: facePoseDetector,
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
            let facePose = try? facePoseDetector?.detectPose(sampleBuffer: sampleBuffer)
            return Promise(
                value: .init(
                    faceDetectorOutput: faceDetectorOutput,
                    cameraProperties: cameraProperties,
                    configuration: configuration,
                    motionBlurResult: motionBlurResult(
                        faceDetectorOutput: faceDetectorOutput
                    ),
                    facePose: facePose
                )
            )
        } catch {
            return Promise(error: error)
        }

    }

    func reset() {
        motionBlurDetector.reset()
        faceDetector.metricsTracker?.reset()
        facePoseDetector?.reset()
    }
}

extension FaceScanner {
    fileprivate func motionBlurResult(
        faceDetectorOutput: FaceDetectorOutput
    ) -> MotionBlurDetector.Output? {
        guard
            faceDetectorOutput.predictions.count == 1,
            let faceRect = faceDetectorOutput.predictions.first?.rect
        else {
            return nil
        }
        let motionBlurOutput = motionBlurDetector.determineMotionBlur(
            documentBounds: faceRect
        )
        return motionBlurOutput
    }
}
