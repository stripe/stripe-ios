//
//  MLModelLoader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/1/22.
//

import Foundation
import CoreML
import Vision
@_spi(STP) import StripeCore

/**
 Loads and compiles CoreML models from a remote URL. The compiled model is saved
 to a cache directory. If a model with the same remote URL is loaded again, the
 cached model will be loaded instead of re-downloading it.
 */
final class MLModelLoader {

    private let loadPromiseCacheQueue = DispatchQueue(label: "com.stripe.ml-loader")
    private var loadPromiseCache: [URL: Promise<MLModel>] = [:]

    let fileDownloader: FileDownloader
    let cacheDirectory: URL

    /**
     - Parameters:
       - fileDownloader: A file downloader used to download files
       - cacheDirectory: File URL corresponding to a directory where the
                         compiled ML model can be cached to. The app must have
                         permission to write to this directory.
     */
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
            try FileManager.default.moveItem(at: compiledModel, to: destinationURL)
            return destinationURL
        } catch {
            return nil
        }
    }

    /**
     Downloads, compiles, and loads a `.mlmodel` file stored on a remote URL.

     If the a model from the given URL has already been successfully compiled
     before, it will be loaded from the cache. Otherwise the file is downloaded
     from the given remote URL, compiled, and loaded into an MLModel.

     - Parameters:
       - remoteURL: The URL to download the model from.

     - Returns: A future resolving to an `MLModel` instantiated from the compiled model.
     */
    func loadModel(
        fromRemote remoteURL: URL
    ) -> Future<MLModel> {
        let returnedPromise = Promise<MLModel>()

        // Dispatch before accessing promise cache
        loadPromiseCacheQueue.async { [weak self] in
            guard let self = self else { return }

            // Check if we've already started downloading the model
            if let cachedPromise = self.loadPromiseCache[remoteURL] {
                return cachedPromise.observe { returnedPromise.fullfill(with: $0) }
            }

            // Check if model is already cached to file system
            let cachedModel = self.getCachedLocation(forRemoteURL: remoteURL)
            if let mlModel = try? MLModel(contentsOf: cachedModel) {
                return returnedPromise.resolve(with: mlModel)
            }

            self.fileDownloader.downloadFileTemporarily(from: remoteURL).chained { [weak self] tmpFileURL -> Promise<MLModel> in
                let compilePromise = Promise<MLModel>()
                compilePromise.fulfill { [weak self] in
                    // Note: The model must be compiled synchronously immediately
                    // after the file is downloaded, otherwise the system will
                    // delete the temporary file url before we've had a chance to
                    // compile it.
                    let tmpCompiledURL = try MLModel.compileModel(at: tmpFileURL)
                    let compiledURL = self?.cache(
                        compiledModel: tmpCompiledURL,
                        downloadedFrom: remoteURL
                    ) ?? tmpCompiledURL
                    return try MLModel(contentsOf: compiledURL)
                }
                return compilePromise
            }.observe { [weak self] result in
                returnedPromise.fullfill(with: result)

                // Remove from promise cache
                self?.loadPromiseCacheQueue.async { [weak self] in
                    self?.loadPromiseCache.removeValue(forKey: remoteURL)
                }
            }

            // Cache the promise
            self.loadPromiseCache[remoteURL] = returnedPromise
        }

        return returnedPromise
    }

    /**
     Downloads, compiles, and loads a `.mlmodel` file stored on a remote URL.

     If the a model from the given URL has already been successfully compiled
     before, it will be loaded from the cache. Otherwise the file is downloaded
     from the given remote URL, compiled, and loaded into an MLModel.

     - Parameters:
       - remoteURL: The URL to download the model from.

     - Returns: A future resolving to a `VNCoreMLModel` instantiated from the compiled model.
     */
    func loadVisionModel(
        fromRemote remoteURL: URL
    ) -> Future<VNCoreMLModel> {
        return loadModel(fromRemote: remoteURL).chained { mlModel in
            let promise = Promise<VNCoreMLModel>()
            promise.fulfill {
                return try VNCoreMLModel(for: mlModel)
            }
            return promise
        }
    }
}
