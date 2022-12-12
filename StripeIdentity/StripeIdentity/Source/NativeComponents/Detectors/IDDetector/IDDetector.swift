//
//  IDDetector.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreVideo
import Foundation
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
import Vision

/// Scans an image using the IDDetector ML model.

final class IDDetector: VisionBasedDetector {
    typealias Output = IDDetectorOutput?
    typealias Configuration = MLDetectorConfiguration

    let model: VNCoreMLModel
    let configuration: Configuration
    let metricsTracker: MLDetectorMetricsTracker? = .init(modelName: "id_detector_v2")

    /// Initializes an `IDDetector`
    /// - Parameters:
    ///   - model: The IDDetector ML model loaded into a `VNCoreMLModel`
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
        // The IDDetector model requires a square region as input, so configure
        // the request to only consider the center-cropped region.
        request.imageCropAndScaleOption = .centerCrop
        return request
    }

    func visionBasedDetectorOutputIfSkipping() -> IDDetectorOutput?? {
        return .none
    }
}
