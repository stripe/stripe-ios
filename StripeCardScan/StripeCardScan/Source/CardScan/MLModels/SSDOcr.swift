//
// SSDOcr.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML

/// Model Prediction Input Type
@available(macOS 10.13.2, iOS 11.2, tvOS 11.2, watchOS 4.2, *)
class SSDOcrInput: MLFeatureProvider {

    /// 0 as color (kCVPixelFormatType_32BGRA) image buffer, 600 pixels wide by 375 pixels high
    var _0: CVPixelBuffer

    var featureNames: Set<String> {
        return ["0"]
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "0" {
            return MLFeatureValue(pixelBuffer: _0)
        }
        return nil
    }

    init(
        _0: CVPixelBuffer
    ) {
        self._0 = _0
    }
}

/// Model Prediction Output Type
@available(macOS 10.13.2, iOS 11.2, tvOS 11.2, watchOS 4.2, *)
class SSDOcrOutput: MLFeatureProvider {

    /// Source provided by CoreML

    private let provider: MLFeatureProvider

    /// MultiArray of shape (1, 1, 1, 3420, 10). The first and second dimensions correspond to sequence and batch size, respectively as multidimensional array of floats
    lazy var scores: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "scores")!.multiArrayValue
    }()!

    /// MultiArray of shape (1, 1, 1, 3420, 4). The first and second dimensions correspond to sequence and batch size, respectively as multidimensional array of floats
    lazy var boxes: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "boxes")!.multiArrayValue
    }()!

    /// MultiArray of shape (1, 1, 1, 3420, 1). The first and second dimensions correspond to sequence and batch size, respectively as multidimensional array of floats
    lazy var filter: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "filter")!.multiArrayValue
    }()!

    var featureNames: Set<String> {
        return self.provider.featureNames
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        return self.provider.featureValue(for: featureName)
    }

    init(
        features: MLFeatureProvider
    ) {
        self.provider = features
    }
}

/// Class for model loading and prediction
@available(macOS 10.13.2, iOS 11.2, tvOS 11.2, watchOS 4.2, *)
@_spi(STP) public class SSDOcr {
    let model: MLModel

    /// URL of model assuming it was installed in the same bundle as this class
    class var urlOfModelInThisBundle: URL {
        let bundle = Bundle(for: self)
        return bundle.url(forResource: "SSDOcr", withExtension: "mlmodelc")!
    }

    ///    Construct SSDOcr instance with an existing MLModel object.
    ///
    ///    Usually the application does not use this initializer unless it makes a subclass of SSDOcr.
    ///    Such application may want to use `MLModel(contentsOfURL:configuration:)` and `SSDOcr.urlOfModelInThisBundle` to create a MLModel object to pass-in.
    ///
    ///    - parameters:
    ///      - model: MLModel object
    init(
        model: MLModel
    ) {
        self.model = model
    }

    ///    Construct SSDOcr instance with explicit path to mlmodelc file
    ///    - parameters:
    ///       - modelURL: the file url of the model
    ///
    ///    - throws: an NSError object that describes the problem
    convenience init(
        contentsOf modelURL: URL
    ) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }

    ///    Make a prediction using the structured interface
    ///
    ///    - parameters:
    ///       - input: the input to the prediction as SSDOcrInput
    ///
    ///    - throws: an NSError object that describes the problem
    ///
    ///    - returns: the result of the prediction as SSDOcrOutput
    func prediction(input: SSDOcrInput) throws -> SSDOcrOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }

    ///    Make a prediction using the structured interface
    ///
    ///    - parameters:
    ///       - input: the input to the prediction as SSDOcrInput
    ///       - options: prediction options
    ///
    ///    - throws: an NSError object that describes the problem
    ///
    ///    - returns: the result of the prediction as SSDOcrOutput
    func prediction(input: SSDOcrInput, options: MLPredictionOptions) throws -> SSDOcrOutput {
        let outFeatures = try model.prediction(from: input, options: options)
        return SSDOcrOutput(features: outFeatures)
    }
}
