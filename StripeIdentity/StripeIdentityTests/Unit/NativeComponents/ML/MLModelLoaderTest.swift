//
//  MLModelLoaderTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import CoreML
import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@testable import StripeIdentity
import XCTest

final class MLModelLoaderTest: XCTestCase {
    private let remoteURL = URL(string: "https://models.example.com/detector.mlmodel?version=1")!
    private var temporaryDirectory: URL!
    private var cacheDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        cacheDirectory = temporaryDirectory.appendingPathComponent("cache")
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: temporaryDirectory)
        try super.tearDownWithError()
    }

    func testConcurrentLoadersShareDownloadAndCompilationButHaveSeparateModels() throws {
        // Given separate loaders that use the same cache and a download held in flight
        let download = Promise<URL>()
        let downloadStarted = expectation(description: "Download started")
        let downloadCount = InvocationCounter()
        let compileCount = InvocationCounter()
        let source = try makeDownloadedFile()
        let compiled = try makeCompiledModel()
        let makeLoader = {
            self.makeLoader(
                download: { _ in
                    downloadCount.increment()
                    downloadStarted.fulfill()
                    return download
                },
                compile: { _ in
                    compileCount.increment()
                    return compiled
                }
            )
        }
        let firstLoader = makeLoader()
        let secondLoader = makeLoader()

        // When both request the same model before the download finishes
        let first = firstLoader.loadModel(fromRemote: remoteURL)
        let second = secondLoader.loadModel(fromRemote: remoteURL)
        wait(for: [downloadStarted], timeout: 5)
        download.resolve(with: source)

        // Then they share the work but each receives its own Core ML instance
        let firstModel = try result(of: first)
        let secondModel = try result(of: second)
        XCTAssertFalse(firstModel === secondModel)
        XCTAssertEqual(downloadCount.value, 1)
        XCTAssertEqual(compileCount.value, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: compiled.path))
    }

    func testDifferentVersionsDownloadIndependently() throws {
        // Given two versions of a model with the same URL path
        let secondURL = URL(string: "https://models.example.com/detector.mlmodel?version=2")!
        let firstDownload = Promise<URL>()
        let secondDownload = Promise<URL>()
        let downloadsStarted = expectation(description: "Both downloads started")
        downloadsStarted.expectedFulfillmentCount = 2
        let downloadCount = InvocationCounter()
        let loader = makeLoader(download: { url in
            downloadCount.increment()
            downloadsStarted.fulfill()
            return url == self.remoteURL ? firstDownload : secondDownload
        })

        // When both versions are requested concurrently
        let first = loader.loadModel(fromRemote: remoteURL)
        let second = loader.loadModel(fromRemote: secondURL)
        wait(for: [downloadsStarted], timeout: 5)
        firstDownload.resolve(with: try makeDownloadedFile())
        secondDownload.resolve(with: try makeDownloadedFile())

        // Then neither version joins the other's request or overwrites its cache entry
        _ = try result(of: first)
        _ = try result(of: second)
        XCTAssertEqual(downloadCount.value, 2)
        let cache = MLModelCache(directory: cacheDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cache.location(for: remoteURL).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: cache.location(for: secondURL).path))
    }

    func testDifferentCacheDirectoriesDoNotSharePendingDownloads() throws {
        let firstDownload = Promise<URL>()
        let secondDownload = Promise<URL>()
        let downloadsStarted = expectation(description: "Both caches download")
        downloadsStarted.expectedFulfillmentCount = 2
        let firstLoader = makeLoader(download: { _ in
            downloadsStarted.fulfill()
            return firstDownload
        })
        let secondDirectory = temporaryDirectory.appendingPathComponent("second-cache")
        let secondLoader = makeLoader(cacheDirectory: secondDirectory, download: { _ in
            downloadsStarted.fulfill()
            return secondDownload
        })

        let first = firstLoader.loadModel(fromRemote: remoteURL)
        let second = secondLoader.loadModel(fromRemote: remoteURL)
        wait(for: [downloadsStarted], timeout: 5)
        firstDownload.resolve(with: try makeDownloadedFile())
        secondDownload.resolve(with: try makeDownloadedFile())

        _ = try result(of: first)
        _ = try result(of: second)
        for directory in [cacheDirectory!, secondDirectory] {
            let cached = MLModelCache(directory: directory).location(for: remoteURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: cached.path))
        }
    }

    func testCacheDirectoryAliasesShareDownloadAndCompilation() throws {
        // Given two paths to the same cache directory and a download held in flight
        let alias = temporaryDirectory.appendingPathComponent("cache-alias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: cacheDirectory)
        let download = Promise<URL>()
        let downloadStarted = expectation(description: "Download started")
        let downloadCount = InvocationCounter()
        let compileCount = InvocationCounter()
        let source = try makeDownloadedFile()
        let compiled = try makeCompiledModel()
        let makeLoader = { (directory: URL) in
            self.makeLoader(
                cacheDirectory: directory,
                download: { _ in
                    downloadCount.increment()
                    downloadStarted.fulfill()
                    return download
                },
                compile: { _ in
                    compileCount.increment()
                    return compiled
                }
            )
        }

        // When loaders using the real path and its alias request the same model
        let first = makeLoader(cacheDirectory).loadModel(fromRemote: remoteURL)
        let second = makeLoader(alias).loadModel(fromRemote: remoteURL)
        wait(for: [downloadStarted], timeout: 5)
        download.resolve(with: source)

        // Then they share the artifact's download and compilation
        _ = try result(of: first)
        _ = try result(of: second)
        XCTAssertEqual(downloadCount.value, 1)
        XCTAssertEqual(compileCount.value, 1)
    }

    func testCompilationAllowsOtherModelsToFinishAndJoinsMatchingRequests() throws {
        // Given a model whose compiler is held in flight
        let secondURL = URL(string: "https://models.example.com/other.mlmodel")!
        let firstSource = try makeDownloadedFile()
        let secondSource = try makeDownloadedFile()
        let compilationStarted = expectation(description: "First model compilation started")
        let finishCompilation = DispatchSemaphore(value: 0)
        defer { finishCompilation.signal() }
        let firstDownloadCount = InvocationCounter()
        let firstCompileCount = InvocationCounter()
        let loader = makeLoader(
            download: { url in
                if url == self.remoteURL {
                    firstDownloadCount.increment()
                    return Promise(value: firstSource)
                }
                XCTAssertEqual(url, secondURL)
                return Promise(value: secondSource)
            },
            compile: { url in
                if url == firstSource {
                    firstCompileCount.increment()
                    compilationStarted.fulfill()
                    XCTAssertEqual(finishCompilation.wait(timeout: .now() + 10), .success)
                }
                return try self.makeCompiledModel()
            }
        )
        let first = loader.loadModel(fromRemote: remoteURL)
        wait(for: [compilationStarted], timeout: 5)

        // When another caller joins that model and an unrelated model is requested
        let joined = loader.loadModel(fromRemote: remoteURL)
        let other = loader.loadModel(fromRemote: secondURL)
        let otherCompleted = expectation(description: "Other model finishes while first compiler is blocked")
        other.observe { _ in otherCompleted.fulfill() }
        wait(for: [otherCompleted], timeout: 5)
        finishCompilation.signal()

        // Then the unrelated model completes independently and the joined request reuses the work
        _ = try result(of: other)
        let firstModel = try result(of: first)
        let joinedModel = try result(of: joined)
        XCTAssertFalse(firstModel === joinedModel)
        XCTAssertEqual(firstDownloadCount.value, 1)
        XCTAssertEqual(firstCompileCount.value, 1)
    }

    func testDownloadFailureIsSharedAndCanBeRetried() throws {
        let pendingDownload = Promise<URL>()
        let downloadStarted = expectation(description: "First download started")
        let downloadCount = InvocationCounter()
        let source = try makeDownloadedFile()
        let loader = makeLoader(download: { _ in
            if downloadCount.increment() == 1 {
                downloadStarted.fulfill()
                return pendingDownload
            }
            return Promise(value: source)
        })

        // Given two callers waiting for the same download
        let first = loader.loadModel(fromRemote: remoteURL)
        let second = loader.loadModel(fromRemote: remoteURL)
        wait(for: [downloadStarted], timeout: 5)

        // When the download fails, both callers receive the error
        pendingDownload.reject(with: TestError.downloadFailed)
        assertFailure(first, equals: .downloadFailed)
        assertFailure(second, equals: .downloadFailed)
        XCTAssertEqual(downloadCount.value, 1)

        // Then a later request can start a new download and succeed
        _ = try result(of: loader.loadModel(fromRemote: remoteURL))
        XCTAssertEqual(downloadCount.value, 2)
    }

    func testCompilationFailureCleansUpDownloadAndCanBeRetried() throws {
        let firstSource = try makeDownloadedFile()
        let secondSource = try makeDownloadedFile()
        let downloadCount = InvocationCounter()
        let compileCount = InvocationCounter()
        let loader = makeLoader(
            download: { _ in
                Promise(value: downloadCount.increment() == 1 ? firstSource : secondSource)
            },
            compile: { _ in
                if compileCount.increment() == 1 {
                    throw TestError.compilationFailed
                }
                return try self.makeCompiledModel()
            }
        )

        assertFailure(loader.loadModel(fromRemote: remoteURL), equals: .compilationFailed)
        XCTAssertFalse(FileManager.default.fileExists(atPath: firstSource.path))

        _ = try result(of: loader.loadModel(fromRemote: remoteURL))
        XCTAssertEqual(downloadCount.value, 2)
        XCTAssertEqual(compileCount.value, 2)
        XCTAssertFalse(FileManager.default.fileExists(atPath: secondSource.path))
    }

    func testInvalidCompiledModelIsNotCachedAndCanBeRetried() throws {
        let firstSource = try makeDownloadedFile()
        let secondSource = try makeDownloadedFile()
        let invalidCompiled = try makeCompiledModel(contents: "invalid")
        let downloadCount = InvocationCounter()
        let compileCount = InvocationCounter()
        let loader = makeLoader(
            download: { _ in
                Promise(value: downloadCount.increment() == 1 ? firstSource : secondSource)
            },
            compile: { _ in
                if compileCount.increment() == 1 {
                    return invalidCompiled
                }
                return try self.makeCompiledModel()
            }
        )

        assertFailure(loader.loadModel(fromRemote: remoteURL), equals: .invalidModel)
        let cached = MLModelCache(directory: cacheDirectory).location(for: remoteURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: cached.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: firstSource.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: invalidCompiled.path))

        _ = try result(of: loader.loadModel(fromRemote: remoteURL))
        XCTAssertEqual(downloadCount.value, 2)
        XCTAssertEqual(try modelContents(at: cached), "valid")
    }

    func testCachedModelIsReusedByAnotherLoaderWithoutDownloading() throws {
        let source = try makeDownloadedFile()
        let firstLoader = makeLoader(download: { _ in Promise(value: source) })
        _ = try result(of: firstLoader.loadModel(fromRemote: remoteURL))

        let secondLoader = makeLoader(download: { _ in
            XCTFail("A valid cached model should not be downloaded again")
            return Promise(error: TestError.downloadFailed)
        })
        _ = try result(of: secondLoader.loadModel(fromRemote: remoteURL))
    }

    func testConcurrentCacheHitsLoadExactlyOneModelPerCaller() throws {
        // Given a cached model whose first load is held until both callers have requested it
        let cached = MLModelCache(directory: cacheDirectory).location(for: remoteURL)
        _ = try makeCompiledModel(at: cached)
        let loadStarted = expectation(description: "First cached model load started")
        let finishLoading = DispatchSemaphore(value: 0)
        defer { finishLoading.signal() }
        let loadCount = InvocationCounter()
        let makeLoader = {
            MLModelLoader(
                cacheDirectory: self.cacheDirectory,
                download: { _ in
                    XCTFail("A valid cached model should not be downloaded again")
                    return Promise(error: TestError.downloadFailed)
                },
                load: { url in
                    XCTAssertEqual(url, cached)
                    if loadCount.increment() == 1 {
                        loadStarted.fulfill()
                        XCTAssertEqual(finishLoading.wait(timeout: .now() + 5), .success)
                    }
                    return MLModel()
                }
            )
        }

        // When two loaders join the same in-flight cache lookup
        let first = makeLoader().loadModel(fromRemote: remoteURL)
        wait(for: [loadStarted], timeout: 5)
        let second = makeLoader().loadModel(fromRemote: remoteURL)
        finishLoading.signal()

        // Then each caller gets its own instance without an extra validation load
        let firstModel = try result(of: first)
        let secondModel = try result(of: second)
        XCTAssertFalse(firstModel === secondModel)
        XCTAssertEqual(loadCount.value, 2)
    }

    func testCorruptCachedModelIsReplacedAfterDownload() throws {
        // Given a cache entry that cannot be loaded
        let cached = MLModelCache(directory: cacheDirectory).location(for: remoteURL)
        _ = try makeCompiledModel(at: cached, contents: "corrupt")
        let source = try makeDownloadedFile()
        let downloadCount = InvocationCounter()
        let loader = makeLoader(download: { _ in
            downloadCount.increment()
            return Promise(value: source)
        })

        // When a valid replacement is downloaded and compiled
        _ = try result(of: loader.loadModel(fromRemote: remoteURL))

        // Then future loads can use the repaired entry
        XCTAssertEqual(downloadCount.value, 1)
        XCTAssertEqual(try modelContents(at: cached), "valid")
        _ = try result(of: loader.loadModel(fromRemote: remoteURL))
        XCTAssertEqual(downloadCount.value, 1)
    }

    func testFailedReplacementValidationPreservesExistingArtifact() throws {
        // Given an existing artifact that failed to load and a replacement that is also invalid
        let cached = MLModelCache(directory: cacheDirectory).location(for: remoteURL)
        _ = try makeCompiledModel(at: cached, contents: "previous")
        let source = try makeDownloadedFile()
        let compiled = try makeCompiledModel(contents: "invalid")
        let loader = makeLoader(
            download: { _ in Promise(value: source) },
            compile: { _ in compiled }
        )

        // When validating the replacement fails
        assertFailure(loader.loadModel(fromRemote: remoteURL), equals: .invalidModel)

        // Then the existing cache entry is preserved and only the new temporary files are removed
        XCTAssertEqual(try modelContents(at: cached), "previous")
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: compiled.path))
    }

    func testCacheWriteFailureStillLoadsDownloadedModel() throws {
        // Given a file where the cache directory should be
        let blockedCacheDirectory = temporaryDirectory.appendingPathComponent("blocked-cache")
        try Data("occupied".utf8).write(to: blockedCacheDirectory)
        let source = try makeDownloadedFile()
        let compiled = try makeCompiledModel()
        let loader = makeLoader(
            cacheDirectory: blockedCacheDirectory,
            download: { _ in Promise(value: source) },
            compile: { _ in compiled }
        )

        // When the model cannot be published to the cache
        _ = try result(of: loader.loadModel(fromRemote: remoteURL))

        // Then loading succeeds from the compiled artifact, which remains usable
        XCTAssertEqual(try modelContents(at: compiled), "valid")
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertEqual(try String(contentsOf: blockedCacheDirectory, encoding: .utf8), "occupied")
    }

    func testLoadCompletesAfterCallerReleasesLoader() throws {
        let download = Promise<URL>()
        let downloadStarted = expectation(description: "Download started")
        var loader: MLModelLoader? = makeLoader(download: { _ in
            downloadStarted.fulfill()
            return download
        })
        let future = loader!.loadModel(fromRemote: remoteURL)
        loader = nil

        wait(for: [downloadStarted], timeout: 5)
        download.resolve(with: try makeDownloadedFile())
        _ = try result(of: future)
    }

    func testRealModelCompilesCachesAndPredictsAfterTemporaryDownloadIsRemoved() throws {
        // Given a Core ML v1 scaler with double input x and output y, using scale 1 and shift 0
        let source = try makeDownloadedFile(data: makeScalerModelData())
        let loader = MLModelLoader(cacheDirectory: cacheDirectory, download: { _ in Promise(value: source) })

        // When real Core ML compilation and loading publish the model
        let model = try result(of: loader.loadModel(fromRemote: remoteURL))
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        let input = try MLDictionaryFeatureProvider(dictionary: ["x": 42.0])
        XCTAssertEqual(try model.prediction(from: input).featureValue(for: "y")?.doubleValue, 42)

        // Then another loader can predict using only the cached model
        let cachedLoader = MLModelLoader(cacheDirectory: cacheDirectory, download: { _ in
            XCTFail("The compiled model should be loaded from disk")
            return Promise(error: TestError.downloadFailed)
        })
        let cachedModel = try result(of: cachedLoader.loadModel(fromRemote: remoteURL))
        XCTAssertFalse(model === cachedModel)
        XCTAssertEqual(try cachedModel.prediction(from: input).featureValue(for: "y")?.doubleValue, 42)
    }

    func testRealModelPredictsFromTemporaryArtifactWhenCachingFails() throws {
        // Given a real model and a file blocking creation of its cache directory
        let blockedCacheDirectory = temporaryDirectory.appendingPathComponent("blocked-cache")
        try Data("occupied".utf8).write(to: blockedCacheDirectory)
        let source = try makeDownloadedFile(data: makeScalerModelData())
        var compiledURL: URL?
        defer {
            if let compiledURL {
                try? FileManager.default.removeItem(at: compiledURL)
            }
        }
        let loader = MLModelLoader(
            cacheDirectory: blockedCacheDirectory,
            download: { _ in Promise(value: source) },
            compile: { url in
                let compiled = try MLModel.compileModel(at: url)
                compiledURL = compiled
                return compiled
            }
        )

        // When compilation succeeds but publication fails
        let model = try result(of: loader.loadModel(fromRemote: remoteURL))

        // Then the retained temporary artifact supports real inference after download cleanup
        let compiled = try XCTUnwrap(compiledURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: compiled.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertEqual(try String(contentsOf: blockedCacheDirectory, encoding: .utf8), "occupied")
        let input = try MLDictionaryFeatureProvider(dictionary: ["x": 42.0])
        XCTAssertEqual(try model.prediction(from: input).featureValue(for: "y")?.doubleValue, 42)
    }

    private func makeScalerModelData() -> Data {
        // Core ML v1 scaler with double input x and output y, using scale 1 and shift 0.
        // The bytes encode Model, ModelDescription, FeatureType, and Scaler from Core ML's protobuf format.
        Data([
            0x08, 0x01,
            0x12, 0x12,
            0x0A, 0x07, 0x0A, 0x01, 0x78, 0x1A, 0x02, 0x12, 0x00,
            0x52, 0x07, 0x0A, 0x01, 0x79, 0x1A, 0x02, 0x12, 0x00,
            0xE2, 0x25, 0x00,
        ])
    }

    private func makeLoader(
        cacheDirectory: URL? = nil,
        download: @escaping (URL) -> Future<URL>,
        compile: ((URL) throws -> URL)? = nil
    ) -> MLModelLoader {
        MLModelLoader(
            cacheDirectory: cacheDirectory ?? self.cacheDirectory,
            download: download,
            compile: compile ?? { _ in try self.makeCompiledModel() },
            load: { url in
                guard (try? self.modelContents(at: url)) == "valid" else {
                    throw TestError.invalidModel
                }
                return MLModel()
            }
        )
    }

    private func makeDownloadedFile(data: Data = Data("download".utf8)) throws -> URL {
        let url = temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mlmodel")
        try data.write(to: url)
        return url
    }

    private func makeCompiledModel(at url: URL? = nil, contents: String = "valid") throws -> URL {
        let url = url ?? temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mlmodelc")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try Data(contents.utf8).write(to: url.appendingPathComponent("model"))
        return url
    }

    private func modelContents(at url: URL) throws -> String {
        try String(contentsOf: url.appendingPathComponent("model"), encoding: .utf8)
    }

    private func result(
        of future: Future<MLModel>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> MLModel {
        let completed = expectation(description: "Model load completed")
        var receivedResult: Result<MLModel, Error>?
        future.observe { result in
            receivedResult = result
            completed.fulfill()
        }
        wait(for: [completed], timeout: 10)
        return try XCTUnwrap(receivedResult, file: file, line: line).get()
    }

    private func assertFailure(
        _ future: Future<MLModel>,
        equals expected: TestError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try result(of: future, file: file, line: line), file: file, line: line) { error in
            XCTAssertEqual(error as? TestError, expected, file: file, line: line)
        }
    }

    private enum TestError: Error, Equatable {
        case downloadFailed
        case compilationFailed
        case invalidModel
    }

    private final class InvocationCounter {
        private let lock = NSLock()
        private var count = 0

        var value: Int {
            lock.lock()
            defer { lock.unlock() }
            return count
        }

        @discardableResult
        func increment() -> Int {
            lock.lock()
            defer { lock.unlock() }
            count += 1
            return count
        }
    }
}
