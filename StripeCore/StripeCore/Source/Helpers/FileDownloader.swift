//
//  FileDownloader.swift
//  StripeCore
//
//  Created by Mel Ludowise on 2/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// Downloads files using a downloadTask.
@_spi(STP) public final class FileDownloader {
    let urlSession: URLSession

    /// Initializes the `FileDownloader`.
    ///
    /// - Parameter urlSession: The session to use to download files with
    public init(
        urlSession: URLSession
    ) {
        self.urlSession = urlSession
    }

    /// Downloads a file from the specified URL and returns a promise that will
    /// resolve to the temporary local file location where the file was downloaded to.
    ///
    /// - Parameter remoteURL: The URL to download the file from.
    public func downloadFileTemporarily(from remoteURL: URL) -> Future<URL> {
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

    /// Downloads a file from the specified URL and returns a promise that will
    /// resolve to the data contents of the file.
    ///
    /// - Parameters:
    ///   - remoteURL: The URL to download the file from
    ///   - fileReadingOptions: Options for reading the file after it's been downloaded locally.
    public func downloadFile(
        from remoteURL: URL,
        fileReadingOptions: Data.ReadingOptions = []
    ) -> Future<Data> {
        return downloadFileTemporarily(from: remoteURL).chained { fileURL in
            let promise = Promise<Data>()
            promise.fulfill {
                return try Data(
                    contentsOf: fileURL,
                    options: fileReadingOptions
                )
            }
            return promise
        }
    }
}
