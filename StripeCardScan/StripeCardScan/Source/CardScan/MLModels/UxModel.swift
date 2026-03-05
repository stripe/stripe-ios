//
// UxModel.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML

/// Model Prediction Input Type
@available(macOS 10.13.2, iOS 11.2, tvOS 11.2, watchOS 4.2, *)
class UxModelInput: MLFeatureProvider {

    /// input1 as color (kCVPixelFormatType_32BGRA) image buffer, 224 pixels wide by 224 pixels high
    var input1: CVPixelBuffer

    var featureNames: Set<String> {
        return ["input1"]
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "input1" {
            return MLFeatureValue(pixelBuffer: input1)
        }
        return nil
    }

    init(
        input1: CVPixelBuffer
    ) {
        self.input1 = input1
    }
}

/// Model Prediction Output Type
@available(macOS 10.13.2, iOS 11.2, tvOS 11.2, watchOS 4.2, *)
class UxModelOutput: MLFeatureProvider {

    /// Source provided by CoreML

    private let provider: MLFeatureProvider

    /// output1 as 3 element vector of doubles
    lazy var output1: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "output1")!.multiArrayValue
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
@_spi(STP) public class UxModel {
    let model: MLModel

    /// URL of model assuming it was installed in the same bundle as this class
    class var urlOfModelInThisBundle: URL {
        let bundle = Bundle(for: self)
        return bundle.url(forResource: "UxModel", withExtension: "mlmodelc")!
    }

    ///    Construct UxModel instance with an existing MLModel object.
    ///
    ///    Usually the application does not use this initializer unless it makes a subclass of UxModel.
    ///    Such application may want to use `MLModel(contentsOfURL:configuration:)` and `UxModel.urlOfModelInThisBundle` to create a MLModel object to pass-in.
    ///
    ///    - parameters:
    ///      - model: MLModel object
    init(
        model: MLModel
    ) {
        self.model = model
    }

    ///    Construct UxModel instance with explicit path to mlmodelc file
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
    ///       - input: the input to the prediction as UxModelInput
    ///
    ///    - throws: an NSError object that describes the problem
    ///
    ///    - returns: the result of the prediction as UxModelOutput
    func prediction(input: UxModelInput) throws -> UxModelOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }

    ///    Make a prediction using the structured interface
    ///
    ///    - parameters:
    ///       - input: the input to the prediction as UxModelInput
    ///       - options: prediction options
    ///
    ///    - throws: an NSError object that describes the problem
    ///
    ///    - returns: the result of the prediction as UxModelOutput
    func prediction(input: UxModelInput, options: MLPredictionOptions) throws -> UxModelOutput {
        let outFeatures = try model.prediction(from: input, options: options)
        return UxModelOutput(features: outFeatures)
    }

    ///    Make a prediction using the convenience interface
    ///
    ///    - parameters:
    ///        - input1 as color (kCVPixelFormatType_32BGRA) image buffer, 224 pixels wide by 224 pixels high
    ///
    ///    - throws: an NSError object that describes the problem
    ///
    ///    - returns: the result of the prediction as UxModelOutput
    func prediction(input1: CVPixelBuffer) throws -> UxModelOutput {
        let input_ = UxModelInput(input1: input1)
        return try self.prediction(input: input_)
    }
}
