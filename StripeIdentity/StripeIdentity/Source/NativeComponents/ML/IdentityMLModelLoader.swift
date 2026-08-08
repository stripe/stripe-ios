//
//  IdentityMLModelLoader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreML
import Foundation
@_spi(STP) import StripeCore
import Vision

enum IdentityMLModelLoaderError: Error, AnalyticLoggableErrorV2 {
    /// Attempted to open a URL that could not be constructed from the given string
    case malformedURL(String)
    /// The ML model never started loading on the client
    case mlModelNeverLoaded

    func analyticLoggableSerializeForLogging() -> [String: Any] {
        switch self {
        case .malformedURL(let value):
            return [
                "type": "malformed_url",
                "value": value,
            ]
        case .mlModelNeverLoaded:
            return [
                "type": "ml_model_never_loaded",
            ]
        }
    }
}

protocol IdentityMLModelLoaderProtocol {
    func documentModels() async -> Result<AnyDocumentScanner, Error>
    func faceModels() async -> Result<AnyFaceScanner, Error>

    func startLoadingDocumentModels(
        from capturePageConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage,
        with sheetController: VerificationSheetControllerProtocol
    )

    func startLoadingFaceModels(
        from selfiePageConfig: StripeAPI.VerificationPageStaticContentSelfiePage
    )
}

/// Loads the ML models used by Identity.

final class IdentityMLModelLoader: IdentityMLModelLoaderProtocol {

    private static let cacheDirectoryName = "com.stripe.stripe-identity"

    // MARK: Instance Properties

    let mlModelLoader: MLModelLoader
    private var documentModelsTask: Task<AnyDocumentScanner, Error>?
    private var faceModelsTask: Task<AnyFaceScanner, Error>?

    func documentModels() async -> Result<AnyDocumentScanner, Error> {
        guard let documentModelsTask else {
            return .failure(IdentityMLModelLoaderError.mlModelNeverLoaded)
        }
        return await documentModelsTask.result
    }

    func faceModels() async -> Result<AnyFaceScanner, Error> {
        guard let faceModelsTask else {
            return .failure(IdentityMLModelLoaderError.mlModelNeverLoaded)
        }
        return await faceModelsTask.result
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
        let cacheDirectory = tempDirectory.appendingPathComponent(
            IdentityMLModelLoader.cacheDirectoryName
        )

        do {
            try FileManager.default.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            return cacheDirectory
        } catch {
            Self.logModelLoadingError(
                error,
                modelType: "shared",
                stage: "create_cache_directory"
            )
            // If creating the subdirectory fails, use temp directory directly
            return tempDirectory
        }
    }

    // MARK: Load models

    /// Starts loading the ML models needed for document scanning.
    ///
    /// - Parameters:
    ///   - documentModelURLs: The URLs of all the ML models required to scan documents
    func startLoadingDocumentModels(
        from capturePageConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage,
        with sheetController: VerificationSheetControllerProtocol
    ) {
        guard let idDetectorURL = URL(string: capturePageConfig.models.idDetectorUrl) else {
            let error = IdentityMLModelLoaderError.malformedURL(
                capturePageConfig.models.idDetectorUrl
            )
            Self.logModelLoadingError(
                error,
                modelType: "document",
                stage: "url_validation"
            )
            documentModelsTask = Task { throw error }
            return
        }

        documentModelsTask = Task { [mlModelLoader] in
            do {
                let idDetectorModel = try await mlModelLoader.loadVisionModel(
                    fromRemote: idDetectorURL
                )
                return AnyDocumentScanner(
                    DocumentScanner(
                        idDetectorModel: idDetectorModel,
                        configuration: .init(from: capturePageConfig),
                        sheetController: sheetController
                    )
                )
            } catch {
                Self.logModelLoadingError(
                    error,
                    modelType: "document",
                    stage: "load"
                )
                throw error
            }
        }
    }

    /// Starts loading the ML models needed for face scanning.
    func startLoadingFaceModels(
        from selfiePageConfig: StripeAPI.VerificationPageStaticContentSelfiePage
    ) {
        guard let faceDetectorURL = URL(string: selfiePageConfig.models.faceDetectorUrl) else {
            let error = IdentityMLModelLoaderError.malformedURL(
                selfiePageConfig.models.faceDetectorUrl
            )
            Self.logModelLoadingError(
                error,
                modelType: "face",
                stage: "url_validation"
            )
            faceModelsTask = Task { throw error }
            return
        }

        faceModelsTask = Task { [mlModelLoader] in
            do {
                let faceDetectorModel = try await mlModelLoader.loadVisionModel(
                    fromRemote: faceDetectorURL
                )
                return AnyFaceScanner(
                    FaceScanner(
                        faceDetectorModel: faceDetectorModel,
                        configuration: .init(from: selfiePageConfig)
                    )
                )
            } catch {
                Self.logModelLoadingError(
                    error,
                    modelType: "face",
                    stage: "load"
                )
                throw error
            }
        }
    }
}

private extension IdentityMLModelLoader {
    static func logModelLoadingError(
        _ error: Error,
        modelType: String,
        stage: String,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) {
        IdentityAnalyticsClient.logUnscopedGenericError(
            error,
            context: "ml_model_load",
            additionalMetadata: [
                "ml_model_type": modelType,
                "ml_model_stage": stage,
            ],
            filePath: filePath,
            line: line
        )
    }
}
