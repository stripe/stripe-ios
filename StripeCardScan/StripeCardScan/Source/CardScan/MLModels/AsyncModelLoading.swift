//
//  AsyncModelLoading.swift
//  StripeCardScan
//
//  Created by Scott Grant on 8/29/22.
//

import CoreML

protocol MLModelClassType {
    static var urlOfModelInThisBundle: URL { get }
}

protocol AsyncMLModelLoading {
    associatedtype ModelClassType

    static func createModelClass(using model: MLModel) -> ModelClassType
    static func asyncLoad(
        contentsOf modelURL: URL,
        configuration: MLModelConfiguration,
        completionHandler handler: @escaping (Swift.Result<ModelClassType, Error>) -> Void
    )
}

extension AsyncMLModelLoading where ModelClassType: MLModelClassType {
    static func asyncLoad(
        contentsOf modelURL: URL = ModelClassType.urlOfModelInThisBundle,
        configuration: MLModelConfiguration = MLModelConfiguration(),
        completionHandler handler: @escaping (Swift.Result<ModelClassType, Error>) -> Void
    ) {
        let deliverResult: (MLModel?, Error?) -> Void = { (model, error) in
            if let error = error {
                handler(.failure(error))
            } else if let model = model {
                handler(.success(Self.createModelClass(using: model)))
            } else {
                fatalError(
                    "SPI failure: -[MLModel loadContentsOfURL:configuration::completionHandler:] vends nil for both model and error."
                )
            }
        }

        if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
            MLModel.__loadContents(
                of: modelURL,
                configuration: configuration,
                completionHandler: deliverResult
            )
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                var model: MLModel?
                var error: Error?

                let result = Swift.Result { try MLModel(contentsOf: modelURL) }
                switch result {
                case .success(let m):
                    model = m
                case .failure(let e):
                    error = e
                }

                deliverResult(model, error)
            }
        }
    }
}
