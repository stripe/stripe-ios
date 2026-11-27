//
//  MLModelCacheTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import XCTest

@_spi(InternalOnlyAPI) @testable import StripeIdentity

final class MLModelCacheTest: XCTestCase {
    private let fileManager = FileManager.default
    private var temporaryDirectory: URL!
    private var cache: MLModelCache!
    private let remoteURL = URL(string: "https://models.stripe.com/detector/v1/model.mlmodel")!

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        cache = MLModelCache(directory: temporaryDirectory.appendingPathComponent("cache", isDirectory: true))
    }

    override func tearDownWithError() throws {
        try fileManager.removeItem(at: temporaryDirectory)
        temporaryDirectory = nil
        cache = nil
        try super.tearDownWithError()
    }

    func testCacheKeyIncludesHostVersionAndPathBoundaries() {
        let urls = [
            "https://models.stripe.com/a_b/c.mlmodel?version=1",
            "https://other.stripe.com/a_b/c.mlmodel?version=1",
            "https://models.stripe.com/a_b/c.mlmodel?version=2",
            "https://models.stripe.com/a/b_c.mlmodel?version=1",
            "https://models.stripe.com/v2/a_b/c.mlmodel?version=1",
        ].map { URL(string: $0)! }

        XCTAssertEqual(Set(urls.map { cache.location(for: $0) }).count, urls.count)
    }

    func testCacheKeyIsStableAndHasBoundedLength() {
        let longURL = URL(string: "https://models.stripe.com/\(String(repeating: "a", count: 1000)).mlmodel?version=2")!
        let anotherCache = MLModelCache(directory: cache.directory)

        XCTAssertEqual(
            cache.location(for: remoteURL).lastPathComponent,
            "url-v1-f4cdfdce5a2696b13a78be0a90b0afafaca3485d8e9230bf2d90d86bc0aef510.mlmodelc"
        )
        XCTAssertEqual(cache.location(for: longURL), anotherCache.location(for: longURL))
        XCTAssertEqual(cache.location(for: longURL).lastPathComponent.count, 80)
        XCTAssertEqual(cache.location(for: longURL).pathExtension, "mlmodelc")
        XCTAssertEqual(cache.location(for: longURL).deletingLastPathComponent().path, cache.directory.path)
    }

    func testStoreCreatesCacheAndPreservesSource() throws {
        // Given a compiled model and a cache directory that does not exist yet
        let compiledModel = try makeModel(contents: "new model")

        // When the compiled model is published
        let destination = try cache.store(compiledModel: compiledModel, for: remoteURL)

        // Then the complete model is cached and the caller still owns the source
        XCTAssertEqual(destination, cache.location(for: remoteURL))
        XCTAssertEqual(try modelContents(at: destination), "new model")
        XCTAssertEqual(try modelContents(at: compiledModel), "new model")
        try assertOnlyCachedModelRemains()
    }

    func testStoreReplacesEntireDirectoryAndCleansStaging() throws {
        // Given an existing compiled model with a file that the replacement does not have
        let previousModel = try makeModel(contents: "old model")
        let destination = try cache.store(compiledModel: previousModel, for: remoteURL)
        let obsoleteFile = destination.appendingPathComponent("obsolete.bin")
        try Data("obsolete".utf8).write(to: obsoleteFile)
        let replacement = try makeModel(contents: "new model")

        // When the replacement is published
        XCTAssertEqual(try cache.store(compiledModel: replacement, for: remoteURL), destination)

        // Then the cache contains only the replacement's files
        XCTAssertEqual(try modelContents(at: destination), "new model")
        XCTAssertFalse(fileManager.fileExists(atPath: obsoleteFile.path))
        XCTAssertEqual(try modelContents(at: replacement), "new model")
        try assertOnlyCachedModelRemains()
    }

    func testFailedReplacementPreservesCachedModelAndSource() throws {
        // Given an existing model that the filesystem will not allow us to replace
        let previousModel = try makeModel(contents: "old model")
        let destination = try cache.store(compiledModel: previousModel, for: remoteURL)
        try fileManager.setAttributes([.immutable: true], ofItemAtPath: destination.path)
        defer { try? fileManager.setAttributes([.immutable: false], ofItemAtPath: destination.path) }
        let replacement = try makeModel(contents: "new model")

        // When publication fails after staging the replacement
        XCTAssertThrowsError(try cache.store(compiledModel: replacement, for: remoteURL))

        // Then the previous model remains usable and the caller can load the replacement directly
        XCTAssertEqual(try modelContents(at: destination), "old model")
        XCTAssertEqual(try modelContents(at: replacement), "new model")
        try assertOnlyCachedModelRemains()
    }

    func testFailedStagingPreservesCachedModelAndCleansStaging() throws {
        // Given an existing model and a missing replacement source
        let previousModel = try makeModel(contents: "old model")
        let destination = try cache.store(compiledModel: previousModel, for: remoteURL)
        let missingSource = temporaryDirectory.appendingPathComponent("missing.mlmodelc")

        // When staging the replacement fails
        XCTAssertThrowsError(try cache.store(compiledModel: missingSource, for: remoteURL))

        // Then the cache is unchanged and no staging directories remain
        XCTAssertEqual(try modelContents(at: destination), "old model")
        try assertOnlyCachedModelRemains()
    }

    private func makeModel(contents: String) throws -> URL {
        let model = temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mlmodelc", isDirectory: true)
        let nestedDirectory = model.appendingPathComponent("model", isDirectory: true)
        try fileManager.createDirectory(at: nestedDirectory, withIntermediateDirectories: true)
        try Data(contents.utf8).write(to: nestedDirectory.appendingPathComponent("weights.bin"))
        return model
    }

    private func modelContents(at model: URL) throws -> String {
        try String(contentsOf: model.appendingPathComponent("model/weights.bin"), encoding: .utf8)
    }

    private func assertOnlyCachedModelRemains(file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertEqual(
            try fileManager.contentsOfDirectory(atPath: cache.directory.path),
            [cache.location(for: remoteURL).lastPathComponent],
            file: file,
            line: line
        )
    }
}
