//
//  MockUploader.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 10/1/26.
//

@testable import StripeCryptoOnramp
import XCTest

/// Suspends each upload until a test supplies its result.
actor MockUploader: DocumentUploading {
    private let uploadStartedExpectation: XCTestExpectation
    private var uploadContinuations: [URL: CheckedContinuation<String, Error>] = [:]

    /// Creates an uploader that fulfills the expectation whenever an upload starts.
    /// - Parameter uploadStartedExpectation: The expectation used to observe upload attempts.
    init(uploadStartedExpectation: XCTestExpectation) {
        self.uploadStartedExpectation = uploadStartedExpectation
    }

    // MARK: - DocumentUploading

    func upload(_ file: DocumentFile, progress: @escaping @Sendable (Double) -> Void) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            uploadContinuations[file.url] = continuation
            uploadStartedExpectation.fulfill()
        }
    }

    // MARK: - MockUploader

    /// Completes the pending upload for the specified file.
    /// - Parameters:
    ///   - fileURL: The temporary file URL supplied when the upload started.
    ///   - result: The uploaded file identifier or error to return to the caller.
    func finish(for fileURL: URL, result: Result<String, Error>) {
        uploadContinuations.removeValue(forKey: fileURL)?.resume(with: result)
    }
}
