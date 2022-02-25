//
//  IDDetectorUnexpectedOutputError.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/27/22.
//

import Foundation
import CoreML
import Vision
@_spi(STP) import StripeCore

/**
 Error thrown when parsing output from the IDDetector model if the output does
 not match the expected features or shape.
 */
struct IDDetectorUnexpectedOutputError: Error {

    /**
     Represents the format of a model feature that will be logged in the event
     the model's feature formats are unexpected
     */
    struct ModelFeatureFormat {
        /// Name of the feature
        let name: String
        /// Type of the feature
        let type: MLFeatureType
        /// If this feature is a multi-array, its shape
        let multiArrayShape: [NSNumber]?
    }

    /// The actual format of the model's features
    let actual: [ModelFeatureFormat]
}

extension IDDetectorUnexpectedOutputError {
    /**
     Convenience method to creating an `unexpectedOutput` from feature observations
     - Parameter observations: The observations that were returned from the ML model.
     */
    @available(iOS 13.0, *)
    init(observations: [VNCoreMLFeatureValueObservation]) {
        self.init(actual: observations.map {
            return .init(
                name: $0.featureName,
                type: $0.featureValue.type,
                multiArrayShape: $0.featureValue.multiArrayValue?.shape
            )
        })
    }
}

// MARK: - AnalyticLoggableError

extension IDDetectorUnexpectedOutputError: AnalyticLoggableError {
    func serializeForLogging() -> [String : Any] {
        return [
            "type": String(describing: type(of: self)),
            "actual": actual.map { featureFormat -> [String: Any] in
                var dict: [String: Any] = [
                    "n": featureFormat.name,
                    "t": featureFormat.type.rawValue
                ]
                if let shape = featureFormat.multiArrayShape {
                    dict["s"] = shape
                }
                return dict
            }
        ]
    }
}
