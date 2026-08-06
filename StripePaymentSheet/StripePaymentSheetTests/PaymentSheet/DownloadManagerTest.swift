//
//  DownloadManagerTest.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) @testable import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
import XCTest

final class DownloadManagerTest: APIStubbedTestCase {
    private let validURL = URL(string: "https://js.stripe.com/validImage.png")!
    private let validURL2 = URL(string: "https://js.stripe.com/validImage2.png")!
    private let invalidURL = URL(string: "https://js.stripe.com/invalidImage.png")!

    private let validImageSize = CGSize(width: 2, height: 3)
    private let validImageSize2 = CGSize(width: 4, height: 5)

    private var urlCache: URLCache!
    private var downloadManager: DownloadManager!
    private var analyticsClient: STPAnalyticsClient!

    override func setUp() {
        super.setUp()
        let configuration = APIStubbedTestCase.stubbedURLSessionConfig()
        urlCache = URLCache(memoryCapacity: 5_000_000, diskCapacity: 0)
        configuration.urlCache = urlCache
        analyticsClient = STPAnalyticsClient()
        downloadManager = DownloadManager(
            urlSessionConfiguration: configuration,
            analyticsClient: analyticsClient
        )
        downloadManager.clearCache()
    }

    func testImageDownloadsAndCachesDecodedImage() async throws {
        stubImage(at: validURL, data: validImageData())

        let downloadedImage = try await downloadManager.image(for: validURL)
        XCTAssertEqual(downloadedImage.size, validImageSize)

        urlCache.removeAllCachedResponses()
        let cachedImage = try XCTUnwrap(downloadManager.cachedImage(for: validURL))
        XCTAssertEqual(cachedImage.pngData(), downloadedImage.pngData())
    }

    func testCachedImageDoesNotReadURLCache() {
        XCTAssertNil(downloadManager.cachedImage(for: validURL))

        seedURLCache(url: validURL, data: validImageData())
        XCTAssertNil(downloadManager.cachedImage(for: validURL))
    }

    func testPromoteCachedImageReadsURLCacheAndCachesDecodedImage() throws {
        seedURLCache(url: validURL, data: validImageData())

        let promotedImage = try XCTUnwrap(downloadManager.promoteCachedImage(for: validURL))
        XCTAssertEqual(promotedImage.size, validImageSize)

        urlCache.removeAllCachedResponses()
        XCTAssertEqual(downloadManager.cachedImage(for: validURL)?.size, validImageSize)
    }

    func testConcurrentImageRequestsSucceed() async throws {
        stubImage(at: validURL, data: validImageData(), responseTime: 0.05)

        let tasks = (0..<3).map { _ in
            Task { try await downloadManager.image(for: validURL) }
        }
        var images: [UIImage] = []
        for task in tasks {
            images.append(try await task.value)
        }
        XCTAssertEqual(images.map(\.size), [validImageSize, validImageSize, validImageSize])
    }

    func testDifferentImagesCanDownloadConcurrently() async throws {
        stubImage(at: validURL, data: validImageData(), responseTime: 0.05)
        stubImage(at: validURL2, data: validImageData2(), responseTime: 0.05)

        let firstTask = Task { try await downloadManager.image(for: validURL) }
        let secondTask = Task { try await downloadManager.image(for: validURL2) }

        let sizes = try await [firstTask.value.size, secondTask.value.size]
        XCTAssertEqual(sizes, [validImageSize, validImageSize2])
    }

    func testClearCacheRemovesResponseAndDecodedImage() async throws {
        stubImage(at: validURL, data: validImageData())
        _ = try await downloadManager.image(for: validURL)
        seedURLCache(url: validURL2, data: validImageData2())

        XCTAssertNotNil(downloadManager.cachedImage(for: validURL))
        XCTAssertNotNil(urlCache.cachedResponse(for: URLRequest(url: validURL2)))

        downloadManager.clearCache()

        XCTAssertNil(downloadManager.cachedImage(for: validURL))
        XCTAssertNil(urlCache.cachedResponse(for: URLRequest(url: validURL2)))
    }

    func testNetworkFailureThrowsAndLogsAnalytics() async throws {
        stub(condition: { $0.url == self.invalidURL }) { _ in
            HTTPStubsResponse(
                error: NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist)
            )
        }

        await XCTAssertThrowsErrorAsync(
            _ = try await self.downloadManager.image(for: self.invalidURL)
        )

        let analytic = try XCTUnwrap(analyticsClient._testLogHistory.first)
        XCTAssertEqual(analytic["event"] as? String, "stripepaymentsheet.downloadmanager.error")
        XCTAssertEqual(analytic["error_code"] as? String, "-1100")
        XCTAssertEqual(analytic["error_type"] as? String, NSURLErrorDomain)
        XCTAssertEqual(analytic["url"] as? String, invalidURL.absoluteString)
    }

    func testInvalidImageDataThrowsAndLogsAnalytics() async throws {
        stubImage(at: validURL, data: Data("invalid image data".utf8))

        await XCTAssertThrowsErrorAsync(
            _ = try await self.downloadManager.image(for: self.validURL)
        )

        let analytic = try XCTUnwrap(analyticsClient._testLogHistory.first)
        XCTAssertEqual(analytic["error_code"] as? String, "failedToMakeImageFromData")
        XCTAssertEqual(
            analytic["error_type"] as? String,
            "StripePaymentSheet.DownloadManager.Error"
        )
        XCTAssertEqual(analytic["url"] as? String, validURL.absoluteString)
    }

    func testCancelledRequestDoesNotLogFailureAnalytics() async {
        let requestStarted = expectation(description: "Request started")
        stub(condition: { $0.url == self.validURL }) { _ in
            requestStarted.fulfill()
            return HTTPStubsResponse(data: self.validImageData(), statusCode: 200, headers: nil)
                .responseTime(1)
        }
        let task = Task {
            try await downloadManager.image(for: validURL)
        }

        await fulfillment(of: [requestStarted], timeout: 1)
        task.cancel()
        _ = try? await task.value

        XCTAssertTrue(analyticsClient._testLogHistory.isEmpty)
    }

    private func stubImage(at url: URL, data: Data, responseTime: TimeInterval = 0) {
        stub(condition: { $0.url == url }) { _ in
            HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
                .responseTime(responseTime)
        }
    }

    private func seedURLCache(url: URL, data: Data) {
        let request = URLRequest(url: url)
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        urlCache.storeCachedResponse(
            CachedURLResponse(response: response, data: data),
            for: request
        )
    }

    private func validImageData() -> Data {
        generateUIImage(size: validImageSize).pngData()!
    }

    private func validImageData2() -> Data {
        generateUIImage(size: validImageSize2).pngData()!
    }

    private func generateUIImage(size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
