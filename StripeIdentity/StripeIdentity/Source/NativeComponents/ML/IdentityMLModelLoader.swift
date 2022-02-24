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

enum IdentityMLModelLoaderError: Error {
    case invalidURL
}

protocol IdentityMLModelLoaderProtocol {
    var documentModelsFuture: Future<DocumentScannerProtocol> { get }

    func startLoadingDocumentModels(
        from documentModelURLs: VerificationPageStaticContentDocumentCaptureModels
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
    private let documentMLModelsPromise = Promise<DocumentScannerProtocol>()

    /// Resolves to the ML models needed for document scanning
    var documentModelsFuture: Future<DocumentScannerProtocol> {
        return documentMLModelsPromise
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
        from documentModelURLs: VerificationPageStaticContentDocumentCaptureModels
    ) {
        guard let idDetectorURL = URL(string: documentModelURLs.idDetectorUrl) else {
            documentMLModelsPromise.reject(with: IdentityMLModelLoaderError.invalidURL)
            return
        }

        mlModelLoader.loadVisionModel(
            fromRemote: idDetectorURL
        ).chained { idDetectorModel in
            return Promise(value: DocumentScanner(idDetectorModel: idDetectorModel))
        }.observe { [weak self] result in
            self?.documentMLModelsPromise.fullfill(with: result)
        }
    }
}
