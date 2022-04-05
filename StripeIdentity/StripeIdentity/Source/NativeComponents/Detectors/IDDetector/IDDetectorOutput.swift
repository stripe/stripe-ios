//
//  IDDetectorOutput.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/27/22.
//

import Foundation
import CoreGraphics
import CoreML
@_spi(STP) import StripeCameraCore
import Vision

/**
 Represents the output from the IDDetector ML model.
 */
struct IDDetectorOutput: Equatable {
    /**
     Classifications returned by the IDDetector ML model.
     The raw value of each classification corresponds to the index in the "scores"
     multi-array of the model's output containing the classification's score.
     */
    enum Classification: Int {
        case passport = 0
        case idCardFront = 1
        case idCardBack = 2
        case invalid = 3
    }

    /// The classification with the highest score
    let classification: Classification

    /// The bounding box of the document
    let documentBounds: CGRect

    /// The scores of all the classifications detected by the model
    let allClassificationScores: [Classification: Float]
}

/**
 Represents a single prediction from the IDDetector ML model.
 The IDDetector outputs a large set of predictions that are then reduced into an
 IDDetectorOutput using the Non-Maximum Suppression algorithm.
 */
struct IDDetectorPrediction: MLBoundingBox {
    let classification: IDDetectorOutput.Classification
    let score: Float
    let rect: CGRect

    // MARK: MLBoundingBox

    var classIndex: Int {
        return classification.rawValue
    }
}

// MARK: - MultiArray

@available(iOS 13, *)
extension IDDetectorOutput: OptionalVisionBasedDetectorOutput {

    /// Expected feature names from the ML model output
    private enum FeatureNames: String {
        case scores
        case boxes
    }

    init?(
        detector: IDDetector,
        observations: [VNObservation],
        originalImageSize: CGSize
    ) throws {
        let featureValueObservations = observations.compactMap { $0 as? VNCoreMLFeatureValueObservation }

        guard let scoresObservation = featureValueObservations.first(where: { $0.featureName == FeatureNames.scores.rawValue }),
              let boxesObservation = featureValueObservations.first(where: { $0.featureName == FeatureNames.boxes.rawValue }),
              let scoresMultiArray = scoresObservation.featureValue.multiArrayValue,
              let boxesMultiArray = boxesObservation.featureValue.multiArrayValue,
              IDDetectorOutput.isValidShape(boxes: boxesMultiArray, scores: scoresMultiArray)
        else {
            throw IDDetectorUnexpectedOutputError(observations: featureValueObservations)
        }

        self.init(
            boxes: boxesMultiArray,
            scores: scoresMultiArray,
            originalImageSize: originalImageSize,
            configuration: detector.configuration
        )
    }

    /**
     Initializes `IDDetectorOutput` from multi arrays of boxes and scores using
     the non-maximum-suppression algorithm to determine the best score and
     bounding box for each classification.
     - Parameters:
       - boxes: The multi array of the "boxes" with a shape of
                1 x numPredictions x 4 where `boxes[0][n]` returns an array of
                `[minX, minY, maxX, maxY]`
       - scores: The multi array of the "scores" with a shape of
                 1 x numPredictions x numClassifications

     - Returns: `nil` if there are no valid predictions for any classification.
     */
    init?(
        boxes: MLMultiArray,
        scores: MLMultiArray,
        originalImageSize: CGSize,
        configuration: IDDetector.Configuration
    ) {
        /*
         NOTE: The number of classifications in `scores` may differ from
         `IDDetectorOutput.Classification` if the model has been updated
         with additional classifications.
         */
        let numClasses = scores.shape[2].intValue
        let numPredictions = scores.shape[1].intValue

        /*
         Aggregate all of the predictions across all the classifications into
         one array of bounding boxes.
         */
        var predictions: [IDDetectorPrediction] = []
        predictions.reserveCapacity(numClasses * numPredictions)

        (0..<numClasses).forEach { rawClassification in
            // If the client doesn't recognize the classification, ignore the prediction
            guard let classification = Classification(rawValue: rawClassification) else {
                return
            }
            predictions += (0..<numPredictions).compactMap { index in
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
                    classification: classification,
                    score: scores[[0, index, rawClassification]].floatValue,
                    rect: rect
                )
            }
        }

        // Use NMS to get the best bounding box for each classification
        // NOTE: The result of `nonMaxSuppressionMultiClass` will be sorted by score
        let bestPredictions = nonMaxSuppressionMultiClass(
            numClasses: numClasses,
            boundingBoxes: predictions,
            scoreThreshold: configuration.minScore,
            iouThreshold: configuration.minIOU,
            maxPerClass: 1,
            maxTotal: numClasses
        ).map { index in
            return predictions[index]
        }

        self.init(
            sortedPredictions: bestPredictions,
            originalImageSize: originalImageSize
        )
    }

    /**
     Initializes `IDDetectorOutput` from a list of predictions.

     - Parameters:
       - sortedPredictions: A list of predictions sorted by score from
                            high to low. There should be, at most, 1 prediction
                            per classification.
     */
    init?(
        sortedPredictions: [IDDetectorPrediction],
        originalImageSize: CGSize
    ) {
        guard let bestPrediction = sortedPredictions.first else {
            return nil
        }
        var allClassificationScores: [Classification: Float] = [:]
        sortedPredictions.forEach { prediction in
            allClassificationScores[prediction.classification] = prediction.score
        }

        /*
         Because the IDDetector model is only scanning the center-cropped
         square region of the original image, the bounding box returned by
         the model is going to be relative to the center-cropped square.
         We need to convert the bounding box into coordinates relative to
         the original image size.
         */
        self.init(
            classification: bestPrediction.classification,
            documentBounds: bestPrediction.rect.convertFromNormalizedCenterCropSquare(
                toOriginalSize: originalImageSize
            ),
            allClassificationScores: allClassificationScores
        )
    }

    /**
     Determines if the multi-arrays output by the IDDetector's ML model have a
     valid shape that can be parsed into a list of predictions.

     - Parameters:
       - boxes: The multi array of the "boxes" with a shape of
                1 x numPredictions x 4 where `boxes[0][n]` returns an array of
                `[minX, minY, maxX, maxY]`
       - scores: The multi array of the "scores" with a shape of
                 1 x numPredictions x numClassifications

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
        scores.shape[2].intValue > 0 &&
        boxes.shape[1] == scores.shape[1]
    }
}
