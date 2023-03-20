//
//  IdentityMLModelLoader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/1/22.
//

import Foundation
import CoreML
import Vision
@_spi(STP) import StripeCore

enum IdentityMLModelLoaderError: Error, AnalyticLoggableError {
    /// Attempted to open a URL that could not be constructed from the given string
    case malformedURL(String)
    /// The ML model never started loading on the client
    case mlModelNeverLoaded

    func analyticLoggableSerializeForLogging() -> [String : Any] {
        switch self {
        case .malformedURL(let value):
            return [
                "type": "malformed_url",
                "value": value
            ]
        case .mlModelNeverLoaded:
            return [
                "type": "ml_model_never_loaded"
            ]
        }
    }
}

protocol IdentityMLModelLoaderProtocol {
    var documentModelsFuture: Future<AnyDocumentScanner> { get }
    var faceModelsFuture: Future<AnyFaceScanner> { get }

    func startLoadingDocumentModels(
        from capturePageConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage
    )

    func startLoadingFaceModels(
        from selfiePageConfig: StripeAPI.VerificationPageStaticContentSelfiePage
    )
}

/**
 Loads the ML models used by Identity.
 */
@available(iOS 13, *)
final class IdentityMLModelLoader: IdentityMLModelLoaderProtocol {

    private static let cacheDirectoryName = "com.stripe.stripe-identity"

    // MARK: Instance Properties

    let mlModelLoader: MLModelLoader
    private let documentMLModelsPromise = Promise<AnyDocumentScanner>(
        error: IdentityMLModelLoaderError.mlModelNeverLoaded
    )
    private let faceMLModelsPromise = Promise<AnyFaceScanner>(
        error: IdentityMLModelLoaderError.mlModelNeverLoaded
    )

    /// Resolves to the ML models needed for document scanning
    var documentModelsFuture: Future<AnyDocumentScanner> {
        return documentMLModelsPromise
    }

    /// Resolves to the ML models needed for face scanning
    var faceModelsFuture: Future<AnyFaceScanner> {
        return faceMLModelsPromise
    }

    // MARK: Init

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        let urlSession = URLSession(configuration: config)

        self.mlModelLoader = .init(
            fileDownloader: FileDownloader(urlSession: urlSession),
            cacheDirectory: IdentityMLModelLoader.createCacheDirectory()
        )
    }

    static func createCacheDirectory() -> URL {
        // Since the models are unlikely to be used after the user has finished
        // verifying their identity, cache them to a temp directory so the
        // system will delete them when it needs the space.
        let tempDirectory = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        )

        // Create a name-spaced subdirectory inside the temp directory so
        // we don't clash with any other files the app is storing here.
        let cacheDirectory = tempDirectory.appendingPathComponent(IdentityMLModelLoader.cacheDirectoryName)

        do {
            try FileManager.default.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            return cacheDirectory
        } catch {
            // If creating the subdirectory fails, use temp directory directly
            return tempDirectory
        }
    }

    // MARK: Load models

    /**
     Starts loading the ML models needed for document scanning. When the models
     are done loading, they can be retrieved by observing `documentModelsFuture`.

     - Parameters:
       - documentModelURLs: The URLs of all the ML models required to scan documents
     */
    func startLoadingDocumentModels(
        from capturePageConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage
    ) {
        guard let idDetectorURL = URL(string: capturePageConfig.models.idDetectorUrl) else {
            documentMLModelsPromise.reject(with: IdentityMLModelLoaderError.malformedURL(
                capturePageConfig.models.idDetectorUrl
            ))
            return
        }

        mlModelLoader.loadVisionModel(
            fromRemote: idDetectorURL
        ).chained { idDetectorModel in
            return Promise(value: .init(DocumentScanner(
                idDetectorModel: idDetectorModel,
                configuration: .init(from: capturePageConfig)
            )))
        }.observe { [weak self] result in
            self?.documentMLModelsPromise.fullfill(with: result)
        }
    }

    /**
     Starts loading the ML models needed for face scanning. When the models
     are done loading, they can be retrieved by observing `faceModelsFuture`.
     */
    func startLoadingFaceModels(
        from selfiePageConfig: StripeAPI.VerificationPageStaticContentSelfiePage
    ) {
        guard let faceDetectorURL = URL(string: selfiePageConfig.models.faceDetectorUrl) else {
            faceMLModelsPromise.reject(with: IdentityMLModelLoaderError.malformedURL(
                selfiePageConfig.models.faceDetectorUrl
            ))
            return
        }

        mlModelLoader.loadVisionModel(
            fromRemote: faceDetectorURL
        ).chained { faceDetectorModel in
            return Promise(value: .init(FaceScanner(
                faceDetectorModel: faceDetectorModel,
                configuration: .init(from: selfiePageConfig)
            )))
        }.observe { [weak self] result in
            self?.faceMLModelsPromise.fullfill(with: result)
        }
    }
}
