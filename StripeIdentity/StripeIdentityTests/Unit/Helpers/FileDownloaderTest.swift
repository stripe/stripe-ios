import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
import XCTest

@testable import StripeIdentity

final class FileDownloaderTest: APIStubbedTestCase {
    func testServerErrorCanBeRetried() {
        let remoteURL = URL(string: "https://example.com/\(UUID().uuidString).mlmodel")!
        let downloader = makeDownloader()
        stub(condition: isAbsoluteURLString(remoteURL.absoluteString)) { _ in
            HTTPStubsResponse(data: Data("not found".utf8), statusCode: 404, headers: nil)
        }
        let failed = expectation(description: "HTTP error rejected")
        downloader.downloadFileTemporarily(from: remoteURL).observe { result in
            switch result {
            case .success(let file):
                try? FileManager.default.removeItem(at: file)
                XCTFail("HTTP error body must not be accepted as a model file")
            case .failure(let error):
                XCTAssertEqual((error as NSError).domain, NSURLErrorDomain)
                XCTAssertEqual((error as NSError).code, URLError.badServerResponse.rawValue)
            }
            failed.fulfill()
        }
        wait(for: [failed], timeout: 3)

        // A later successful response remains readable after the download callback.
        let bytes = Data("model bytes".utf8)
        stub(condition: isAbsoluteURLString(remoteURL.absoluteString)) { _ in
            HTTPStubsResponse(data: bytes, statusCode: 200, headers: nil)
        }
        let retried = expectation(description: "Retry downloaded")
        downloader.downloadFileTemporarily(from: remoteURL).observe { result in
            switch result {
            case .success(let file):
                defer { try? FileManager.default.removeItem(at: file) }
                XCTAssertEqual(try? Data(contentsOf: file), bytes)
            case .failure(let error):
                XCTFail("Retry failed: \(error)")
            }
            retried.fulfill()
        }
        wait(for: [retried], timeout: 3)
    }

    func testFailedCompilationRemovesDownloadedSource() throws {
        let remoteURL = URL(string: "https://example.com/\(UUID().uuidString).mlmodel")!
        let cache = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: cache) }
        stub(condition: isAbsoluteURLString(remoteURL.absoluteString)) { _ in
            HTTPStubsResponse(data: Data("invalid model".utf8), statusCode: 200, headers: nil)
        }
        let loader = MLModelLoader(fileDownloader: makeDownloader(), cacheDirectory: cache)
        let completed = expectation(description: "Compilation failed")
        loader.loadModel(fromRemote: remoteURL).observe { result in
            switch result {
            case .success:
                XCTFail("Invalid model must fail compilation")
            case .failure(let error):
                XCTAssertNotEqual((error as NSError).domain, NSURLErrorDomain)
            }
            completed.fulfill()
        }
        wait(for: [completed], timeout: 3)

        let remaining = try FileManager.default.contentsOfDirectory(
            at: FileManager.default.temporaryDirectory, includingPropertiesForKeys: nil
        ).filter { $0.lastPathComponent.hasSuffix(remoteURL.lastPathComponent) }
        defer { remaining.forEach { try? FileManager.default.removeItem(at: $0) } }
        XCTAssertTrue(remaining.isEmpty, "Downloaded model source should be removed after compilation fails")
    }

    private func makeDownloader() -> FileDownloader {
        let config = URLSessionConfiguration.ephemeral
        HTTPStubs.setEnabled(true, for: config)
        return FileDownloader(urlSession: URLSession(configuration: config))
    }
}
