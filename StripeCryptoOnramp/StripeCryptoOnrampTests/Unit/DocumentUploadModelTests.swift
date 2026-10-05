//
//  DocumentUploadModelTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 9/16/26.
//

import Combine
@testable import StripeCryptoOnramp
import XCTest

@MainActor
final class DocumentUploadModelTests: XCTestCase {
    func testSuccessfulUploadExposesFileIDAndDeletesLocalCopy() async throws {
        let uploadStartedExpectation = expectation(description: "Upload started")
        let uploader = MockUploader(uploadStartedExpectation: uploadStartedExpectation)
        let model = DocumentUploadModel(uploader: uploader)
        let selectedFile = try makeFile()
        let uploadCompletedExpectation = expectation(description: "Upload completed")

        let documentObservation = model.$document.sink { document in
            if case .uploaded = document?.status {
                uploadCompletedExpectation.fulfill()
            }
        }

        defer {
            documentObservation.cancel()
        }

        model.select(selectedFile)
        await fulfillment(of: [uploadStartedExpectation], timeout: 2)
        XCTAssertNil(model.uploadedFileID)

        await uploader.finish(for: selectedFile.url, result: .success("file_success"))
        await fulfillment(of: [uploadCompletedExpectation], timeout: 2)

        XCTAssertEqual(model.uploadedFileID, "file_success")
        XCTAssertFalse(FileManager.default.fileExists(atPath: selectedFile.url.path))
    }

    func testRemovedUploadCannotRestoreItsFileAfterLateCompletion() async throws {
        let uploadStartedExpectation = expectation(description: "Upload started")
        let uploader = MockUploader(uploadStartedExpectation: uploadStartedExpectation)
        let model = DocumentUploadModel(uploader: uploader)
        let selectedFile = try makeFile()
        model.select(selectedFile)

        await fulfillment(of: [uploadStartedExpectation], timeout: 2)

        model.remove()

        let unexpectedDocumentRestorationExpectation = expectation(description: "Removed document stays removed")
        unexpectedDocumentRestorationExpectation.isInverted = true

        let documentObservation = model.$document.sink {
            if $0 != nil {
                unexpectedDocumentRestorationExpectation.fulfill()
            }
        }

        defer {
            documentObservation.cancel()
        }

        await uploader.finish(for: selectedFile.url, result: .success("file_obsolete"))
        await fulfillment(of: [unexpectedDocumentRestorationExpectation], timeout: 0.2)

        XCTAssertNil(model.document)
        XCTAssertNil(model.uploadedFileID)
    }

    func testClosingFlowIgnoresLateFileSelection() async throws {
        let unexpectedUploadExpectation = expectation(description: "No upload after closing")
        unexpectedUploadExpectation.isInverted = true

        let model = DocumentUploadModel(uploader: MockUploader(uploadStartedExpectation: unexpectedUploadExpectation))
        model.cancel()
        model.select(try makeFile())

        await fulfillment(of: [unexpectedUploadExpectation], timeout: 0.2)
        XCTAssertNil(model.document)
    }

    private func makeFile() throws -> DocumentFile {
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
        try Data("%PDF-1.7\nexample".utf8).write(to: sourceURL)

        defer {
            try? FileManager.default.removeItem(at: sourceURL)
        }

        return try DocumentFile.copy(from: sourceURL, acceptedFormats: ["pdf"], maximumFileSize: 100)
    }
}
