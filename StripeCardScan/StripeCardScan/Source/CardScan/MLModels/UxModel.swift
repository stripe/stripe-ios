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

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    convenience init(
        input1With input1: CGImage
    ) throws {
        let __input1 = try MLFeatureValue(
            cgImage: input1,
            pixelsWide: 224,
            pixelsHigh: 224,
            pixelFormatType: kCVPixelFormatType_32ARGB,
            options: nil
        ).imageBufferValue!
        self.init(input1: __input1)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    convenience init(
        input1At input1: URL
    ) throws {
        let __input1 = try MLFeatureValue(
            imageAt: input1,
            pixelsWide: 224,
            pixelsHigh: 224,
            pixelFormatType: kCVPixelFormatType_32ARGB,
            options: nil
        ).imageBufferValue!
        self.init(input1: __input1)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func setInput1(with input1: CGImage) throws {
        self.input1 = try MLFeatureValue(
            cgImage: input1,
            pixelsWide: 224,
            pixelsHigh: 224,
            pixelFormatType: kCVPixelFormatType_32ARGB,
            options: nil
        ).imageBufferValue!
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func setInput1(with input1: URL) throws {
        self.input1 = try MLFeatureValue(
            imageAt: input1,
            pixelsWide: 224,
            pixelsHigh: 224,
            pixelFormatType: kCVPixelFormatType_32ARGB,
            options: nil
        ).imageBufferValue!
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
        output1: MLMultiArray
    ) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: [
            "output1": MLFeatureValue(multiArray: output1)
        ])
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

    ///    Construct UxModel instance by automatically loading the model from the app's bundle.
    @available(
        *,
        deprecated,
        message: "Use init(configuration:) instead and handle errors appropriately."
    )
    convenience init() {
        try! self.init(contentsOf: type(of: self).urlOfModelInThisBundle)
    }

    ///    Construct a model with configuration
    ///
    ///    - parameters:
    ///       - configuration: the desired model configuration
    ///
    ///    - throws: an NSError object that describes the problem
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)
    convenience init(
        configuration: MLModelConfiguration
    ) throws {
        try self.init(
            contentsOf: type(of: self).urlOfModelInThisBundle,
            configuration: configuration
        )
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

    ///    Construct a model with URL of the .mlmodelc directory and configuration
    ///
    ///    - parameters:
    ///       - modelURL: the file url of the model
    ///       - configuration: the desired model configuration
    ///
    ///    - throws: an NSError object that describes the problem
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)
    convenience init(
        contentsOf modelURL: URL,
        configuration: MLModelConfiguration
    ) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }

    ///    Construct UxModel instance asynchronously with optional configuration.
    ///
    ///    Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.
    ///
    ///    - parameters:
    ///      - configuration: the desired model configuration
    ///      - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    class func load(
        configuration: MLModelConfiguration = MLModelConfiguration(),
        completionHandler handler: @escaping (Swift.Result<UxModel, Error>) -> Void
    ) {
        return self.load(
            contentsOf: self.urlOfModelInThisBundle,
            configuration: configuration,
            completionHandler: handler
        )
    }

    ///    Construct UxModel instance asynchronously with URL of the .mlmodelc directory with optional configuration.
    ///
    ///    Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.
    ///
    ///    - parameters:
    ///      - modelURL: the URL to the model
    ///      - configuration: the desired model configuration
    ///      - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    class func load(
        contentsOf modelURL: URL,
        configuration: MLModelConfiguration = MLModelConfiguration(),
        completionHandler handler: @escaping (Swift.Result<UxModel, Error>) -> Void
    ) {
        MLModel.__loadContents(of: modelURL, configuration: configuration) { (model, error) in
            if let error = error {
                handler(.failure(error))
            } else if let model = model {
                handler(.success(UxModel(model: model)))
            } else {
                fatalError(
                    "SPI failure: -[MLModel loadContentsOfURL:configuration::completionHandler:] vends nil for both model and error."
                )
            }
        }
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

    ///    Make a batch prediction using the structured interface
    ///
    ///    - parameters:
    ///       - inputs: the inputs to the prediction as [UxModelInput]
    ///       - options: prediction options
    ///
    ///    - throws: an NSError object that describes the problem
    ///
    ///    - returns: the result of the prediction as [UxModelOutput]
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)
    func predictions(
        inputs: [UxModelInput],
        options: MLPredictionOptions = MLPredictionOptions()
    ) throws -> [UxModelOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results: [UxModelOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result = UxModelOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
