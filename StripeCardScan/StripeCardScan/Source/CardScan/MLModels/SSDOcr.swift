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

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    convenience init(
        _0With _0: CGImage
    ) throws {
        let ___0 = try MLFeatureValue(
            cgImage: _0,
            pixelsWide: 600,
            pixelsHigh: 375,
            pixelFormatType: kCVPixelFormatType_32ARGB,
            options: nil
        ).imageBufferValue!
        self.init(_0: ___0)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    convenience init(
        _0At _0: URL
    ) throws {
        let ___0 = try MLFeatureValue(
            imageAt: _0,
            pixelsWide: 600,
            pixelsHigh: 375,
            pixelFormatType: kCVPixelFormatType_32ARGB,
            options: nil
        ).imageBufferValue!
        self.init(_0: ___0)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func set_0(with _0: CGImage) throws {
        self._0 = try MLFeatureValue(
            cgImage: _0,
            pixelsWide: 600,
            pixelsHigh: 375,
            pixelFormatType: kCVPixelFormatType_32ARGB,
            options: nil
        ).imageBufferValue!
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func set_0(with _0: URL) throws {
        self._0 = try MLFeatureValue(
            imageAt: _0,
            pixelsWide: 600,
            pixelsHigh: 375,
            pixelFormatType: kCVPixelFormatType_32ARGB,
            options: nil
        ).imageBufferValue!
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
        scores: MLMultiArray,
        boxes: MLMultiArray,
        filter: MLMultiArray
    ) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: [
            "scores": MLFeatureValue(multiArray: scores),
            "boxes": MLFeatureValue(multiArray: boxes),
            "filter": MLFeatureValue(multiArray: filter),
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

    ///    Construct SSDOcr instance by automatically loading the model from the app's bundle.
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

    ///    Construct SSDOcr instance asynchronously with optional configuration.
    ///
    ///    Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.
    ///
    ///    - parameters:
    ///      - configuration: the desired model configuration
    ///      - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    class func load(
        configuration: MLModelConfiguration = MLModelConfiguration(),
        completionHandler handler: @escaping (Swift.Result<SSDOcr, Error>) -> Void
    ) {
        return self.load(
            contentsOf: self.urlOfModelInThisBundle,
            configuration: configuration,
            completionHandler: handler
        )
    }

    ///    Construct SSDOcr instance asynchronously with URL of the .mlmodelc directory with optional configuration.
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
        completionHandler handler: @escaping (Swift.Result<SSDOcr, Error>) -> Void
    ) {
        MLModel.__loadContents(of: modelURL, configuration: configuration) { (model, error) in
            if let error = error {
                handler(.failure(error))
            } else if let model = model {
                handler(.success(SSDOcr(model: model)))
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

    ///    Make a prediction using the convenience interface
    ///
    ///    - parameters:
    ///        - _0 as color (kCVPixelFormatType_32BGRA) image buffer, 600 pixels wide by 375 pixels high
    ///
    ///    - throws: an NSError object that describes the problem
    ///
    ///    - returns: the result of the prediction as SSDOcrOutput
    func prediction(_0: CVPixelBuffer) throws -> SSDOcrOutput {
        let input_ = SSDOcrInput(_0: _0)
        return try self.prediction(input: input_)
    }

    ///    Make a batch prediction using the structured interface
    ///
    ///    - parameters:
    ///       - inputs: the inputs to the prediction as [SSDOcrInput]
    ///       - options: prediction options
    ///
    ///    - throws: an NSError object that describes the problem
    ///
    ///    - returns: the result of the prediction as [SSDOcrOutput]
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)
    func predictions(
        inputs: [SSDOcrInput],
        options: MLPredictionOptions = MLPredictionOptions()
    ) throws -> [SSDOcrOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results: [SSDOcrOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result = SSDOcrOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
