//
//  FaceDetectorOutput.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/10/22.
//

import Foundation
import CoreGraphics
import CoreML
@_spi(STP) import StripeCameraCore
import Vision

/**
 Represents the output from the FaceDetector ML model.
 */
struct FaceDetectorOutput: Equatable {
    let predictions: [FaceDetectorPrediction]
}

struct FaceDetectorPrediction: Equatable {
    /// The bounding box of the detected face
    let rect: CGRect

    /// The score of the detected face
    let score: Float
}

// MARK: MLBoundingBox

extension FaceDetectorPrediction: MLBoundingBox {
    // FaceDetector has no classification, so each prediction has the same classIndex
    var classIndex: Int {
        return 0
    }
}

// MARK: - MultiArray
@available(iOS 13, *)
extension FaceDetectorOutput: VisionBasedDetectorOutput {

    /// We want to know if 0, 1, or > 1 faces are returned by the model, so tell
    /// NMS to return a max of 2 results.
    static let nmsMaxResults: Int = 2

    /// Expected feature names from the ML model output
    private enum FeatureNames: String {
        case scores
        case boxes
    }

    init(
        detector: FaceDetector,
        observations: [VNObservation],
        originalImageSize: CGSize
    ) throws {
        let featureValueObservations = observations.compactMap { $0 as? VNCoreMLFeatureValueObservation }

        guard let scoresObservation = featureValueObservations.first(where: { $0.featureName == FeatureNames.scores.rawValue }),
              let boxesObservation = featureValueObservations.first(where: { $0.featureName == FeatureNames.boxes.rawValue }),
              let scoresMultiArray = scoresObservation.featureValue.multiArrayValue,
              let boxesMultiArray = boxesObservation.featureValue.multiArrayValue,
              FaceDetectorOutput.isValidShape(boxes: boxesMultiArray, scores: scoresMultiArray)
        else {
            throw MLModelUnexpectedOutputError(observations: featureValueObservations)
        }

        self.init(
            boxes: boxesMultiArray,
            scores: scoresMultiArray,
            originalImageSize: originalImageSize,
            configuration: detector.configuration
        )
    }

    /**
     Initializes `FaceDetectorOutput` from multi arrays of boxes and scores using
     the non-maximum-suppression algorithm to determine the best scores and
     bounding boxes.
     - Parameters:
       - boxes: The multi array of the "boxes" with a shape of
                1 x numPredictions x 4 where `boxes[0][n]` returns an array of
                `[minX, minY, maxX, maxY]`
       - scores: The multi array of the "scores" with a shape of
                 1 x numPredictions x 1
     */
    init(
        boxes: MLMultiArray,
        scores: MLMultiArray,
        originalImageSize: CGSize,
        configuration: FaceDetector.Configuration
    ) {
        let numPredictions = scores.shape[1].intValue

        let predictions: [FaceDetectorPrediction] = (0..<numPredictions).compactMap { index in

            let score = scores[[0, index, 0]].floatValue

            // Discard results that have a score lower than minScore
            guard score >= configuration.minScore else {
                return nil
            }

            let rect = CGRect(
                x: boxes[[0, index, 0]].doubleValue,
                y: boxes[[0, index, 1]].doubleValue,
                width: boxes[[0, index, 2]].doubleValue,
                height: boxes[[0, index, 3]].doubleValue
            )
            // Discard results that are outside the bounds of the image
            guard CGRect.normalizedBounds.contains(rect) else {
                return nil
            }
            return .init(
                rect: rect,
                score: score
            )
        }

        // Use NMS to get the best bounding boxes
        // NOTE: The result of `nonMaxSuppression` will be sorted by score
        let bestPredictions = nonMaxSuppression(
            boundingBoxes: predictions,
            iouThreshold: configuration.minIOU,
            maxBoxes: FaceDetectorOutput.nmsMaxResults
        ).map { index in
            return predictions[index]
        }

        self.init(
            centerCroppedSquarePredictions: bestPredictions,
            originalImageSize: originalImageSize
        )
    }

    /**
     Initializes `FaceDetectorOutput` from a list of predictions using a
     center-cropped square coordinate space.

     - Note:
     Because the FaceDetector model is only scanning the center-cropped
     square region of the original image, the bounding box returned by
     the model is going to be relative to the center-cropped square.
     We need to convert the bounding box into coordinates relative to
     the original image size.

     - Parameters:
       - predictions: A list of predictions using a center-cropped square coordinate space.
       - originalImageSize: The size of the original image.
     */
    init(
        centerCroppedSquarePredictions predictions: [FaceDetectorPrediction],
        originalImageSize: CGSize
    ) {
        self.init(predictions: predictions.map {
                .init(
                    rect: $0.rect.convertFromNormalizedCenterCropSquare(
                        toOriginalSize: originalImageSize
                    ),
                    score: $0.score
                )
        })
    }

    /**
     Determines if the multi-arrays output by the FaceDetector's ML model have a
     valid shape that can be parsed into a list of predictions.

     - Parameters:
       - boxes: The multi array of the "boxes" with a shape of
                1 x numPredictions x 4 where `boxes[0][n]` returns an array of
                `[minX, minY, maxX, maxY]`
       - scores: The multi array of the "scores" with a shape of
                 1 x numPredictions x 1

     - Returns: True if the multi-arrays have a valid shape that can be parsed into predictions.
     */
    static func isValidShape(
        boxes: MLMultiArray,
        scores: MLMultiArray
    ) -> Bool {
        return boxes.shape.count == 3 &&
        boxes.shape[0] == 1 &&
        boxes.shape[2] == 4 &&
        scores.shape.count == 3 &&
        scores.shape[0] == 1 &&
        scores.shape[2] == 1 &&
        boxes.shape[1] == scores.shape[1]
    }
}
