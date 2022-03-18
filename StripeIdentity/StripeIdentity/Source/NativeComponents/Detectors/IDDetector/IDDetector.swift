//
//  IDDetector.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/27/22.
//

import Foundation
import CoreVideo
import Vision
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore

/**
 Scans an image using the IDDetector ML model.
 */
@available(iOS 13, *)
final class IDDetector: VisionBasedDetector {
    typealias Output = IDDetectorOutput?

    struct Configuration {
        /**
         Minimum score threshold used when performing non-maximum suppression
         on the model's output
         */
        let minScore: Float

        /**
         Minimum IOU threshold used when performing non-maximum suppression on
         the model's output
         */
        let minIOU: Float
    }

    let model: VNCoreMLModel
    let configuration: Configuration

    /**
     Initializes an `IDDetector`
     - Parameters:
       - model: The IDDetector ML model loaded into a `VNCoreMLModel`
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
        // The IDDetector model requires a square region as input, so configure
        // the request to only consider the center-cropped region.
        request.imageCropAndScaleOption = .centerCrop
        return request
    }

    func visionBasedDetectorOutputIfSkipping() -> IDDetectorOutput?? {
        return .none
    }
}
