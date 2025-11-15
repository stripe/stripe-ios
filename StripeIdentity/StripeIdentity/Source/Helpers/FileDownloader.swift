//
//  FileDownloader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// Downloads files using a downloadTask.
final class FileDownloader {
    let urlSession: URLSession

    /// Initializes the `FileDownloader`.
    ///
    /// - Parameter urlSession: The session to use to download files with
    init(
        urlSession: URLSession
    ) {
        self.urlSession = urlSession
    }

    /// Downloads a file from the specified URL and returns a promise that will
    /// resolve to the temporary local file location where the file was downloaded to.
    ///
    /// - Parameter remoteURL: The URL to download the file from.
    func downloadFileTemporarily(from remoteURL: URL) -> Future<URL> {
        let promise = Promise<URL>()

        let request = URLRequest(url: remoteURL)

        let downloadTask = urlSession.downloadTask(with: request) { url, _, error in

            if let error = error {
                return promise.reject(with: error)
            }

            guard let url = url else {
                return promise.reject(with: NSError.stp_genericConnectionError())
            }

            // Move the file to a temporary cache directory after generating a unique name to avoid conflicts.
            let fileManager = FileManager.default
            let uniqueFileName = "\(UUID().uuidString)_" + remoteURL.lastPathComponent
            let temporaryFileURL = fileManager.temporaryDirectory.appendingPathComponent(uniqueFileName)

            do {
                try fileManager.moveItem(at: url, to: temporaryFileURL)
            } catch {
                return promise.reject(with: error)
            }

            promise.resolve(with: temporaryFileURL)
        }
        downloadTask.resume()

        return promise
    }
}
