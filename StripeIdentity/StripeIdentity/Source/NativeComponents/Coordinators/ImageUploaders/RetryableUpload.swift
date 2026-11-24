//
//  RetryableUpload.swift
//  StripeIdentity
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// The upload of one file. The uploaders keep one for each file, so a retry
/// uploads again only the files that failed. Starts the upload when created;
/// `restart()` starts it again.
final class RetryableUpload<Value> {
    private let operation: () async throws -> Value
    /// Read and replaced only on the main actor after init.
    private(set) var task: Task<Value, Error>

    init(_ operation: @escaping () async throws -> Value) {
        self.operation = operation
        self.task = Task(operation: operation)
    }

    /// Waits for every upload to finish, and returns the uploads that failed.
    @MainActor static func failed(_ uploads: [RetryableUpload?]) async -> [RetryableUpload] {
        var failedUploads: [RetryableUpload] = []
        for upload in uploads.compactMap({ $0 }) {
            if case .failure = await upload.task.result {
                failedUploads.append(upload)
            }
        }
        return failedUploads
    }

    @MainActor func restart() {
        task = Task(operation: operation)
    }
}
