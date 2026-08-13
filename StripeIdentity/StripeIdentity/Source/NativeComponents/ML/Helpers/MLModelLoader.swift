//
//  MLModelLoader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreML
import Foundation
import Vision

/// Loads and compiles CoreML models from a remote URL. The compiled model is saved
/// to a cache directory. If a model with the same remote URL is loaded again, the
/// cached model will be loaded instead of re-downloading it.
final class MLModelLoader: @unchecked Sendable {

    private let loadTaskCacheQueue = DispatchQueue(label: "com.stripe.ml-loader")
    private var loadTaskCache: [URL: Task<MLModel, Error>] = [:]

    let fileDownloader: FileDownloader
    let cacheDirectory: URL

    /// - Parameters:
    ///   - fileDownloader: A file downloader used to download files
    ///   - cacheDirectory: File URL corresponding to a directory where the
    ///                     compiled ML model can be cached to. The app must have
    ///                     permission to write to this directory.
    init(
        fileDownloader: FileDownloader,
        cacheDirectory: URL
    ) {
        self.fileDownloader = fileDownloader
        self.cacheDirectory = cacheDirectory
    }

    private func getCachedLocation(forRemoteURL remoteURL: URL) -> URL {
        let components = remoteURL.pathComponents.joined(separator: "_")
        return cacheDirectory.appendingPathComponent(components)
    }

    private func cache(compiledModel: URL, downloadedFrom remoteURL: URL) -> URL? {
        let destinationURL = getCachedLocation(forRemoteURL: remoteURL)
        do {
            let fileManager = FileManager.default

            // Remove any previously cached entry to avoid a failure when moving into place
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            try fileManager.moveItem(at: compiledModel, to: destinationURL)
            return destinationURL
        } catch {
            Self.logModelLoadingError(
                error,
                stage: "cache_compiled_model"
            )
            return nil
        }
    }

    /// Downloads, compiles, and loads a `.mlmodel` file stored on a remote URL.
    ///
    /// If the a model from the given URL has already been successfully compiled
    /// before, it will be loaded from the cache. Otherwise the file is downloaded
    /// from the given remote URL, compiled, and loaded into an MLModel.
    ///
    /// - Parameters:
    ///   - remoteURL: The URL to download the model from.
    ///
    /// - Returns: An `MLModel` instantiated from the compiled model.
    func loadModel(
        fromRemote remoteURL: URL
    ) async throws -> MLModel {
        let (task, ownsCacheEntry) = loadTaskCacheQueue.sync {
            if let task = loadTaskCache[remoteURL] {
                return (task, false)
            }

            let task = Task {
                try await self.loadModelFromCacheOrRemote(remoteURL)
            }
            loadTaskCache[remoteURL] = task
            return (task, true)
        }

        defer {
            if ownsCacheEntry {
                _ = loadTaskCacheQueue.sync {
                    loadTaskCache.removeValue(forKey: remoteURL)
                }
            }
        }
        return try await task.value
    }

    /// Downloads, compiles, and loads a `.mlmodel` file stored on a remote URL.
    ///
    /// If the a model from the given URL has already been successfully compiled
    /// before, it will be loaded from the cache. Otherwise the file is downloaded
    /// from the given remote URL, compiled, and loaded into an MLModel.
    ///
    /// - Parameters:
    ///   - remoteURL: The URL to download the model from.
    ///
    /// - Returns: A `VNCoreMLModel` instantiated from the compiled model.
    func loadVisionModel(
        fromRemote remoteURL: URL
    ) async throws -> VNCoreMLModel {
        try VNCoreMLModel(for: await loadModel(fromRemote: remoteURL))
    }
}

private extension MLModelLoader {
    func loadModelFromCacheOrRemote(_ remoteURL: URL) async throws -> MLModel {
        let cachedModel = getCachedLocation(forRemoteURL: remoteURL)
        do {
            return try MLModel(contentsOf: cachedModel)
        } catch {
            if FileManager.default.fileExists(atPath: cachedModel.path) {
                Self.logModelLoadingError(
                    error,
                    stage: "load_cached_model"
                )

                // If the model failed to load because it was corrupted, delete the artifact
                try? FileManager.default.removeItem(at: cachedModel)
            }
        }

        return try await downloadCompileAndLoadModel(fromRemote: remoteURL)
    }

    func downloadCompileAndLoadModel(fromRemote remoteURL: URL) async throws -> MLModel {
        let tmpFileURL = try await fileDownloader.downloadFileTemporarily(from: remoteURL)
        let tmpCompiledURL = try MLModel.compileModel(at: tmpFileURL)
        let compiledURL = cache(
            compiledModel: tmpCompiledURL,
            downloadedFrom: remoteURL
        ) ?? tmpCompiledURL
        return try MLModel(contentsOf: compiledURL)
    }

    static func logModelLoadingError(
        _ error: Error,
        stage: String,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) {
        IdentityAnalyticsClient.logUnscopedGenericError(
            error,
            context: "ml_model_load",
            additionalMetadata: [
                "ml_model_stage": stage,
            ],
            filePath: filePath,
            line: line
        )
    }
}
