//
//  MLModelLoaderTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable import StripeIdentity

final class MLModelLoaderTest: XCTestCase {
    private let remoteURL = URL(string: "https://example.com/model.mlmodel")!
    private var cacheDirectory: URL!
    private var loader: MLModelLoader!
    private var downloadCount: DownloadCount!

    override func setUp() {
        super.setUp()
        cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        loader = MLModelLoader(
            fileDownloader: FileDownloader(urlSession: URLSession(configuration: .ephemeral)),
            cacheDirectory: cacheDirectory
        )

        // Every download fails after a short delay, so loads that start together overlap.
        let downloadCount = DownloadCount()
        self.downloadCount = downloadCount
        stub(condition: isAbsoluteURLString(remoteURL.absoluteString)) { _ in
            downloadCount.increment()
            return HTTPStubsResponse(error: URLError(.notConnectedToInternet))
                .responseTime(0.2)
        }
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        try? FileManager.default.removeItem(at: cacheDirectory)
        super.tearDown()
    }

    func testConcurrentLoadsOfSameURLShareOneDownload() async {
        // When two loads of the same model start together
        let first = Task { await loadError() }
        let second = Task { await loadError() }
        let errors = [await first.value, await second.value]

        // Then the model is downloaded once and both loads get its failure
        XCTAssertEqual(downloadCount.value, 1)
        XCTAssertEqual(errors.compactMap { $0 }.count, 2)
    }

    func testLoadAfterFailedLoadDownloadsAgain() async {
        // Given a load that failed
        let firstError = await loadError()
        XCTAssertNotNil(firstError)

        // When the same model is loaded again
        let secondError = await loadError()

        // Then the model is downloaded again instead of reusing the failed load
        XCTAssertNotNil(secondError)
        XCTAssertEqual(downloadCount.value, 2)
    }
}

private extension MLModelLoaderTest {
    func loadError() async -> Error? {
        do {
            _ = try await loader.loadModel(fromRemote: remoteURL)
            return nil
        } catch {
            return error
        }
    }
}

/// Counts download requests, which the stub records from URL loading threads.
private final class DownloadCount: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock()
        count += 1
        lock.unlock()
    }
}
