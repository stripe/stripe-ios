//
//  FaceDetector.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/10/22.
//

import Foundation
import CoreVideo
import Vision
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore

/**
 Scans an image using the FaceDetector ML model.
 */
@available(iOS 13, *)
final class FaceDetector: VisionBasedDetector {
    typealias Output = FaceDetectorOutput

    typealias Configuration = MLDetectorConfiguration

    let model: VNCoreMLModel
    let configuration: Configuration
    let metricsTracker: MLDetectorMetricsTracker? = .init(modelName: "face_detector_v1")

    /**
     Initializes an `FaceDetector`
     - Parameters:
       - model: The FaceDetector ML model loaded into a `VNCoreMLModel`
       - configuration: The configuration for this detector
     */
    init(
        model: VNCoreMLModel,
        configuration: Configuration
    ) {
        self.model = model
        self.configuration = configuration
    }

    func visionBasedDetectorMakeRequest() -> VNImageBasedRequest {
        let request = VNCoreMLRequest(model: model)
        // The FaceDetector model requires a square region as input, so configure
        // the request to only consider the center-cropped region.
        request.imageCropAndScaleOption = .centerCrop
        return request
    }

    func visionBasedDetectorOutputIfSkipping() -> FaceDetectorOutput? {
        return .none
    }
}
