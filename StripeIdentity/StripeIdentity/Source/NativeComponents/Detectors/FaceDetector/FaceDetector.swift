//
//  FaceDetector.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreVideo
import Foundation
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
import Vision

/// Scans an image using the FaceDetector ML model.

final class FaceDetector: VisionBasedDetector {
    typealias Output = FaceDetectorOutput

    typealias Configuration = MLDetectorConfiguration

    let model: VNCoreMLModel
    let configuration: Configuration
    let metricsTracker: MLDetectorMetricsTracker? = .init(modelName: "face_detector_v1")

    /// Initializes an `FaceDetector`
    /// - Parameters:
    ///   - model: The FaceDetector ML model loaded into a `VNCoreMLModel`
    ///   - configuration: The configuration for this detector
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
