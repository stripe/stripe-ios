//
//  MLModelCache.swift
//  StripeIdentity
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import CryptoKit
import Darwin
import Foundation

/// Stores compiled models under a stable key for the complete remote URL.
struct MLModelCache {
    let directory: URL

    init(directory: URL) {
        self.directory = directory.standardizedFileURL.resolvingSymlinksInPath()
    }

    func location(for remoteURL: URL) -> URL {
        // The API currently provides a model URL, not a separate model ID or version.
        // Include the host and query so versioned URLs cannot share the wrong model.
        let digest = SHA256.hash(data: Data(remoteURL.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        return directory.appendingPathComponent("url-v1-\(digest).mlmodelc", isDirectory: true)
    }

    /// Publishes an already validated compiled model without exposing a partial cache entry.
    /// The caller retains ownership of `compiledModel`, including when publication fails.
    func store(compiledModel: URL, for remoteURL: URL) throws -> URL {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        // Stage on the destination volume so publication can be a single rename.
        let stagingDirectory = directory.appendingPathComponent(".staging-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: false)
        defer { try? fileManager.removeItem(at: stagingDirectory) }

        let stagedModel = stagingDirectory.appendingPathComponent("model.mlmodelc", isDirectory: true)
        try fileManager.copyItem(at: compiledModel, to: stagedModel)

        let destination = location(for: remoteURL)
        if renamex_np(stagedModel.path, destination.path, UInt32(RENAME_EXCL)) != 0 {
            let creationError = errno
            guard creationError == EEXIST else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(creationError))
            }

            // A regular rename cannot replace a nonempty directory. Swap the complete
            // artifacts atomically, then remove the old artifact with the staging directory.
            guard renamex_np(stagedModel.path, destination.path, UInt32(RENAME_SWAP)) == 0 else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
            }
        }

        return destination
    }
}
