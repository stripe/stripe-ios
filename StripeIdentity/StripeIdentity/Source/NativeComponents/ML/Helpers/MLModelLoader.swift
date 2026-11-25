//
//  MLModelLoader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreML
import Foundation
@_spi(InternalOnlyAPI) import StripeCore
import Vision

/// Loads and compiles CoreML models from a remote URL. The compiled model is saved
/// to a cache directory. If a model with the same remote URL is loaded again, the
/// cached model will be loaded instead of re-downloading it.
final class MLModelLoader {

    private typealias Completion = (Result<URL, Error>, MLModel?) -> Void

    // All loaders share the disk cache, so coordinate by its canonical artifact URL.
    // Only the registry runs on this queue; downloads and Core ML work run separately.
    private static let coordinationQueue = DispatchQueue(label: "com.stripe.ml-loader")
    private static let workQueue = DispatchQueue(label: "com.stripe.ml-loader.work", qos: .userInitiated, attributes: .concurrent)
    private static var pendingLoads: [URL: [Completion]] = [:]

    private let cache: MLModelCache
    private let download: (URL) -> Future<URL>
    private let compile: (URL) throws -> URL
    private let load: (URL) throws -> MLModel

    /// - Parameters:
    ///   - fileDownloader: A file downloader used to download files
    ///   - cacheDirectory: File URL corresponding to a directory where the
    ///                     compiled ML model can be cached to. The app must have
    ///                     permission to write to this directory.
    convenience init(
        fileDownloader: FileDownloader,
        cacheDirectory: URL
    ) {
        self.init(
            cacheDirectory: cacheDirectory,
            download: fileDownloader.downloadFileTemporarily(from:)
        )
    }

    init(
        cacheDirectory: URL,
        download: @escaping (URL) -> Future<URL>,
        compile: @escaping (URL) throws -> URL = MLModel.compileModel(at:),
        load: @escaping (URL) throws -> MLModel = { try MLModel(contentsOf: $0) }
    ) {
        self.cache = MLModelCache(directory: cacheDirectory)
        self.download = download
        self.compile = compile
        self.load = load
    }

    private func compileAndCache(downloadedModel: URL, from remoteURL: URL) throws -> URL {
        let fileManager = FileManager.default
        defer { try? fileManager.removeItem(at: downloadedModel) }

        let compiledModel = try compile(downloadedModel)
        var keepCompiledModel = false
        defer {
            if !keepCompiledModel {
                try? fileManager.removeItem(at: compiledModel)
            }
        }

        // Validate before publishing, so a bad download cannot replace an existing model.
        _ = try load(compiledModel)
        do {
            return try cache.store(compiledModel: compiledModel, for: remoteURL)
        } catch {
            Self.logModelLoadingError(
                error,
                stage: "cache_compiled_model"
            )
            // Core ML may continue reading these files after loading. Leave a fallback
            // artifact in the temporary directory for the system to clean up later.
            keepCompiledModel = true
            return compiledModel
        }
    }

    /// Downloads, compiles, and loads a `.mlmodel` file stored on a remote URL.
    ///
    /// If a model from the given URL has already been successfully compiled
    /// before, it will be loaded from the cache. Otherwise the file is downloaded
    /// from the given remote URL, compiled, and loaded into an MLModel.
    ///
    /// - Parameters:
    ///   - remoteURL: The URL to download the model from.
    ///
    /// - Returns: A future resolving to an `MLModel` instantiated from the compiled model.
    func loadModel(
        fromRemote remoteURL: URL
    ) -> Future<MLModel> {
        let returnedPromise = Promise<MLModel>()

        let completion: Completion = { result, loadedModel in
            Self.workQueue.async {
                // Share artifacts, not MLModel instances: different scanners perform
                // inference on different queues and need their own model instance.
                if let loadedModel {
                    returnedPromise.resolve(with: loadedModel)
                    return
                }
                returnedPromise.fullfill(with: result.flatMap { url in
                    Result { try self.load(url) }
                })
            }
        }

        Self.coordinationQueue.async {
            let cachedModel = self.cache.location(for: remoteURL)
            if Self.pendingLoads[cachedModel] != nil {
                Self.pendingLoads[cachedModel]?.append(completion)
                return
            }
            Self.pendingLoads[cachedModel] = [completion]

            Self.workQueue.async {
                do {
                    let model = try self.load(cachedModel)
                    Self.complete(.success(cachedModel), for: cachedModel, loadedModel: model)
                } catch {
                    if FileManager.default.fileExists(atPath: cachedModel.path) {
                        Self.logModelLoadingError(error, stage: "load_cached_model")
                    }

                    // Keep an existing artifact until its replacement is ready.
                    self.download(remoteURL).observe(on: Self.workQueue) { result in
                        let compiledResult = result.flatMap { downloadedModel in
                            Result { try self.compileAndCache(downloadedModel: downloadedModel, from: remoteURL) }
                        }
                        Self.complete(compiledResult, for: cachedModel)
                    }
                }
            }
        }

        return returnedPromise
    }

    private static func complete(_ result: Result<URL, Error>, for cachedModel: URL, loadedModel: MLModel? = nil) {
        coordinationQueue.async {
            // Remove before notifying callers, so failed work can be retried immediately.
            let completions = pendingLoads.removeValue(forKey: cachedModel) ?? []
            for (index, completion) in completions.enumerated() {
                // A cache hit already loaded a model. Give it only to the first caller
                // to avoid loading twice while keeping every caller's instance separate.
                completion(result, index == 0 ? loadedModel : nil)
            }
        }
    }

    /// Downloads, compiles, and loads a `.mlmodel` file stored on a remote URL.
    ///
    /// If a model from the given URL has already been successfully compiled
    /// before, it will be loaded from the cache. Otherwise the file is downloaded
    /// from the given remote URL, compiled, and loaded into an MLModel.
    ///
    /// - Parameters:
    ///   - remoteURL: The URL to download the model from.
    ///
    /// - Returns: A future resolving to a `VNCoreMLModel` instantiated from the compiled model.
    func loadVisionModel(
        fromRemote remoteURL: URL
    ) -> Future<VNCoreMLModel> {
        return loadModel(fromRemote: remoteURL).chained(on: Self.workQueue) { mlModel in
            let promise = Promise<VNCoreMLModel>()
            promise.fulfill {
                return try VNCoreMLModel(for: mlModel)
            }
            return promise
        }
    }
}

private extension MLModelLoader {
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
