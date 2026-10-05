//
//  DocumentCollectionModelTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 9/30/26.
//

import Combine
@testable import StripeCryptoOnramp
import XCTest

@MainActor
final class DocumentCollectionModelTests: XCTestCase {
    func testRestoringAndEditingUploadedFilesDoesNotUploadThemAgain() async {
        let unexpectedUploadExpectation = expectation(description: "Saved files are not uploaded again")
        unexpectedUploadExpectation.isInverted = true

        let uploadedFiles: [DocumentUploadModel.UploadedFile] = [
            .init(name: "first.pdf", fileID: "file_first"),
            .init(name: "second.pdf", fileID: "file_second"),
        ]

        let collection = DocumentCollectionModel(uploader: MockUploader(uploadStartedExpectation: unexpectedUploadExpectation), uploadedFiles: uploadedFiles)

        XCTAssertTrue(collection.isComplete)
        XCTAssertEqual(collection.uploadedFiles, uploadedFiles)
        collection.remove(id: collection.files[0].id)
        XCTAssertEqual(collection.uploadedFiles, [uploadedFiles[1]])
        collection.cancel()

        await fulfillment(of: [unexpectedUploadExpectation], timeout: 0.2)
    }

    func testRemovingOneUploadDoesNotAffectAnotherAndClosedCollectionIgnoresSelection() async throws {
        let uploadsStartedExpectation = expectation(description: "Both uploads started")
        uploadsStartedExpectation.expectedFulfillmentCount = 2

        let uploader = MockUploader(uploadStartedExpectation: uploadsStartedExpectation)
        let collection = DocumentCollectionModel(uploader: uploader)
        let firstFile = try makeFile(name: "first.pdf")
        let secondFile = try makeFile(name: "second.pdf")
        collection.add(firstFile)
        collection.add(secondFile)

        await fulfillment(of: [uploadsStartedExpectation], timeout: 2)
        XCTAssertFalse(collection.isComplete)
        collection.remove(id: collection.files[0].id)

        let uploadCompletedExpectation = expectation(description: "Remaining upload completes")
        let observation = collection.files[0].upload.$document.sink { document in
            if case .uploaded = document?.status {
                uploadCompletedExpectation.fulfill()
            }
        }

        defer {
            observation.cancel()
        }

        await uploader.finish(for: firstFile.url, result: .success("file_removed"))
        await uploader.finish(for: secondFile.url, result: .success("file_retained"))
        await fulfillment(of: [uploadCompletedExpectation], timeout: 2)

        XCTAssertTrue(collection.isComplete)
        XCTAssertEqual(collection.uploadedFiles, [.init(name: "second.pdf", fileID: "file_retained")])
        collection.cancel()
        collection.add(try makeFile(name: "late.pdf"))
        XCTAssertTrue(collection.files.isEmpty)
    }

    private func makeFile(name: String) throws -> DocumentFile {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let source = directory.appendingPathComponent(name)
        try Data("%PDF-1.7\nexample".utf8).write(to: source)
        return try DocumentFile.copy(from: source, acceptedFormats: ["pdf"], maximumFileSize: 100)
    }
}
