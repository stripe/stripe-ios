//
//  FaceScanner.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/10/22.
//

import CoreVideo
import Vision
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore

typealias AnyFaceScanner = AnyImageScanner<FaceScannerOutput>

@available(iOS 13, *)
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
        configuration: Configuration = .default
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

@available(iOS 13, *)
extension FaceScanner: ImageScanner {
    typealias Output = FaceScannerOutput

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        cameraProperties: CameraSession.DeviceProperties?
    ) throws -> FaceScannerOutput {
        return .init(
            faceDetectorOutput: try faceDetector.scanImage(
                pixelBuffer: pixelBuffer
            ),
            cameraProperties: cameraProperties,
            configuration: configuration
        )
    }

    func reset() {
        // Nothing to reset
    }
}
