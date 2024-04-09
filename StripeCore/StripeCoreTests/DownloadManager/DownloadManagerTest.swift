import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP)@testable import StripeCore
import StripeCoreTestUtils
//
//  DownloadManagerTest.swift
//  StripeCoreTests
//
//
import XCTest

class DownloadManagerTest: APIStubbedTestCase {
    let validURL = URL(string: "https://js.stripe.com/validImage.png")!
    let validURL2 = URL(string: "https://js.stripe.com/validImage2.png")!
    let invalidURL = URL(string: "https://js.stripe.com/invalidImage.png")!

    let placeholderImageSize = CGSize(width: 1.0, height: 1.0)
    let validImageSize = CGSize(width: 2.0, height: 3.0)
    let validImageSize2 = CGSize(width: 4.0, height: 5.0)

    var urlSessionConfig: URLSessionConfiguration!
    var rm: DownloadManager!
    var analyticsClient: STPAnalyticsClient!

    override func setUp() {
        super.setUp()
        self.urlSessionConfig = APIStubbedTestCase.stubbedURLSessionConfig()
        self.analyticsClient = STPAnalyticsClient()
        self.rm = DownloadManager(urlSessionConfiguration: urlSessionConfig, analyticsClient: analyticsClient)
        clearCaches()
    }

    private func clearCaches() {
        self.rm.resetDiskCache()

        let clearCacheExpectation = self.expectation(description: "Clear cache")
        Task {
            await self.rm.imageCache.clearCache()
            clearCacheExpectation.fulfill()
        }

        wait(for: [clearCacheExpectation], timeout: 10)
    }

    func testSynchronous_validImage() {
        stub(condition: { request in
            return request.url?.path.contains("/validImage.png") ?? false
        }) { _ in
            return HTTPStubsResponse(data: self.validImageData(), statusCode: 200, headers: nil)
        }

        let image = rm.downloadImage(url: validURL, placeholder: nil, updateHandler: nil)
        XCTAssertEqual(image.size, validImageSize)
    }

    func testSynchronous_validImageIsCached() {
        let expectedRequest = expectation(description: "Request is only called once")

        stub(condition: { request in
            return request.url?.path.contains("/validImage.png") ?? false
        }) { _ in
            expectedRequest.fulfill()
            return HTTPStubsResponse(data: self.validImageData(), statusCode: 200, headers: nil)
        }

        let image = rm.downloadImage(url: validURL, placeholder: nil, updateHandler: nil)
        XCTAssertEqual(image.size, validImageSize)

        wait(for: [expectedRequest], timeout: 1.0)

        let cachedImageWithoutNetworkCall = rm.downloadImage(url: validURL, placeholder: nil, updateHandler: nil)
        XCTAssertEqual(cachedImageWithoutNetworkCall.size, validImageSize)
    }

    func testSynchronous_validImageCacheIsCleared() {
        var numTimesCalled = 0
        let expectedRequest1 = expectation(description: "First request")
        let expectedRequest2 = expectation(description: "Second request")

        stub(condition: { request in
            return request.url?.path.contains("/validImage.png") ?? false
        }) { _ in
            if numTimesCalled == 0 {
                expectedRequest1.fulfill()
                numTimesCalled += 1
            } else if numTimesCalled == 1 {
                expectedRequest2.fulfill()
                numTimesCalled += 1
            }
            return HTTPStubsResponse(data: self.validImageData(), statusCode: 200, headers: nil)
        }

        let image = rm.downloadImage(url: validURL, placeholder: nil, updateHandler: nil)
        XCTAssertEqual(image.size, validImageSize)
        wait(for: [expectedRequest1], timeout: 1.0)

        clearCaches()

        let cachedImageWithoutNetworkCall = rm.downloadImage(url: validURL, placeholder: nil, updateHandler: nil)
        XCTAssertEqual(cachedImageWithoutNetworkCall.size, validImageSize)
        wait(for: [expectedRequest2], timeout: 1.0)
    }

    func testSynchronous_invalidImage() {
        stub(condition: { request in
            return request.url?.path.contains("/invalidImage.png") ?? false
        }) { _ in
            return HTTPStubsResponse(error: NotFoundError())
        }

        let image = rm.downloadImage(url: invalidURL, placeholder: nil, updateHandler: nil)

        XCTAssertEqual(image.size, placeholderImageSize)
    }

    func testAsync_validImage() {
        let expected_imageUpdaterCalled = expectation(description: "updateHandler is called")

        stub(condition: { request in
            return request.url?.path.contains("/validImage.png") ?? false
        }) { _ in
            return HTTPStubsResponse(data: self.validImageData(), statusCode: 200, headers: nil)
        }

        let image = rm.downloadImage(
            url: validURL, placeholder: nil,
            updateHandler: { image in
                XCTAssertEqual(image.size, self.validImageSize)
                expected_imageUpdaterCalled.fulfill()
            }
        )

        XCTAssertEqual(image.size, placeholderImageSize)
        wait(for: [expected_imageUpdaterCalled], timeout: 1.0)
    }

    func testAsync_validImageIsCached() {
        var stickyFlag = false
        let expected1 = expectation(description: "updateHandler is called")

        stub(condition: { request in
            return request.url?.path.contains("/validImage.png") ?? false
        }) { _ in
            if !stickyFlag {
                stickyFlag = true
            } else {
                XCTFail("Request should not be called twice")
            }
            return HTTPStubsResponse(data: self.validImageData(), statusCode: 200, headers: nil)
        }

        let image = rm.downloadImage(
            url: validURL, placeholder: nil,
            updateHandler: { image in
                XCTAssertEqual(image.size, self.validImageSize)
                expected1.fulfill()
            }
        )

        XCTAssertEqual(image.size, placeholderImageSize)
        wait(for: [expected1], timeout: 1.0)

        let expected2 = expectation(
            description: "updateHandler will be called when image is cached"
        )

        _ = rm.downloadImage(
            url: validURL, placeholder: nil,
            updateHandler: { image in
                XCTAssertEqual(image.size, self.validImageSize)
                expected2.fulfill()
            }
        )

        waitForExpectations(timeout: 0.5)
    }
    func testAsync_validImageCacheIsCleared() {
        var numTimesCalled = 0
        let expected1 = expectation(description: "updateHandler is called")

        stub(condition: { request in
            return request.url?.path.contains("/validImage.png") ?? false
        }) { _ in
            if numTimesCalled != 0 && numTimesCalled != 1 {
                XCTFail("Request called more than 2 times")
            }
            numTimesCalled += 1
            return HTTPStubsResponse(data: self.validImageData(), statusCode: 200, headers: nil)
        }

        let image = rm.downloadImage(
            url: validURL, placeholder: nil,
            updateHandler: { image in
                XCTAssertEqual(image.size, self.validImageSize)
                expected1.fulfill()
            }
        )

        XCTAssertEqual(image.size, placeholderImageSize)
        wait(for: [expected1], timeout: 1.0)

        clearCaches()

        let expected2 = expectation(description: "updateHandler us called a second time")
        let image2 = rm.downloadImage(
            url: validURL, placeholder: nil,
            updateHandler: { image in
                XCTAssertEqual(image.size, self.validImageSize)
                expected2.fulfill()
            }
        )

        XCTAssertEqual(image2.size, self.placeholderImageSize)
        wait(for: [expected2], timeout: 1.0)
    }

    func testAsync_invalidImage() {
        let expected = expectation(description: "updateHandler should not be called")
        expected.isInverted = true
        stub(condition: { request in
            return request.url?.path.contains("/invalidImage.png") ?? false
        }) { _ in
            return HTTPStubsResponse(error: NotFoundError())
        }

        let image = rm.downloadImage(
            url: invalidURL, placeholder: nil,
            updateHandler: { image in
                XCTAssertEqual(image.size, self.validImageSize)
                expected.fulfill()
            }
        )

        XCTAssertEqual(image.size, placeholderImageSize)
        waitForExpectations(timeout: 0.5)
    }

    func testAsync_validImage_avoidDeadLockInCallback() {
        let expected_imageUpdater1 = expectation(description: "updateHandler for first image")
        let expected_imageUpdater2 = expectation(description: "updateHandler for second image")

        stub(condition: { request in
            return request.url?.path.contains("/validImage.png") ?? false
        }) { _ in
            return HTTPStubsResponse(data: self.validImageData(), statusCode: 200, headers: nil)
        }

        stub(condition: { request in
            return request.url?.path.contains("/validImage2.png") ?? false
        }) { _ in
            return HTTPStubsResponse(data: self.validImageData2(), statusCode: 200, headers: nil)
        }

        let image = rm.downloadImage(
            url: validURL, placeholder: nil,
            updateHandler: { cb_image1 in
                XCTAssertEqual(cb_image1.size, self.validImageSize)
                expected_imageUpdater1.fulfill()
                let image2 = self.rm.downloadImage(
                    url: self.validURL2, placeholder: nil,
                    updateHandler: { cb_image2 in
                        XCTAssertEqual(cb_image2.size, self.validImageSize2)
                        expected_imageUpdater2.fulfill()
                    }
                )
                XCTAssertEqual(image2.size, self.placeholderImageSize)
            }
        )

        XCTAssertEqual(image.size, placeholderImageSize)
        wait(for: [expected_imageUpdater1], timeout: 1.0)
        wait(for: [expected_imageUpdater2], timeout: 1.0)

    }

    func testConcurrentDownloadsForSameURL() {
        let downloadExpectation = expectation(description: "Download image concurrently")
        downloadExpectation.expectedFulfillmentCount = 3 // Assuming 3 concurrent requests

        stub(condition: isHost("js.stripe.com") && isPath("/validImage.png")) { _ in
            return HTTPStubsResponse(data: self.validImageData(), statusCode: 200, headers: nil).responseTime(0.5) // Simulate network delay
        }

        // Start 3 concurrent download tasks for the same URL
        DispatchQueue.concurrentPerform(iterations: 3) { _ in
            _  = self.rm.downloadImage(url: self.validURL, placeholder: nil) { image in
                XCTAssertEqual(image.size, self.validImageSize, "Downloaded image size should match the expected size")
                downloadExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5)
    }

    func testImageNamefromURL() {
        let img0 = URL(string: "http://js.stripe.com/icon0.png")!.lastPathComponent
        XCTAssertEqual(img0, "icon0.png")

        let img1 = URL(string: "http://js.stripe.com/icon1.png?key1=value1")!.lastPathComponent
        XCTAssertEqual(img1, "icon1.png")
    }

    func test_persistToMemory() async throws {
        var cachedImage = await rm.imageCache.cachedImageNamed("imgName")
        XCTAssertNil(cachedImage)

        let validImageData = validImageData()
        let image = try rm.persistToMemory(validImageData, forImageName: "imgName")
        sleep(1) // `persistToMemory` uses a `Task` to async finish the storing of images, wait for it.
        
        XCTAssertEqual(image.size, validImageSize)
        cachedImage = await rm.imageCache.cachedImageNamed("imgName")
        XCTAssertNotNil(cachedImage)
    }

    func testBadNetworkResponse() throws {
        stub(condition: { request in
            return request.url == self.validURL
        }) { _ in
            return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist))
        }

        let placeholder = rm.imagePlaceHolder()
        let image = rm.downloadImage(url: validURL, placeholder: placeholder, updateHandler: nil)

        XCTAssertEqual(image, placeholder)

        // Validate analytic
        let firstAnalytic = try XCTUnwrap(analyticsClient._testLogHistory.first)
        XCTAssertEqual("stripecore.downloadmanager.error", firstAnalytic["event"] as? String)
        XCTAssertEqual("-1100", firstAnalytic["error_code"] as? String)
        XCTAssertEqual(NSURLErrorDomain, firstAnalytic["error_type"] as? String)
        XCTAssertEqual(self.validURL.absoluteString, firstAnalytic["url"] as? String)
    }

    func testInvalidImageData() throws {
        stub(condition: { request in
            return request.url == self.validURL
        }) { _ in
            return HTTPStubsResponse(data: "invalid image data".data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        let placeholder = rm.imagePlaceHolder()
        let image = rm.downloadImage(url: validURL, placeholder: placeholder, updateHandler: nil)

        XCTAssertEqual(image, placeholder)

        // Validate analytic
        let firstAnalytic = try XCTUnwrap(analyticsClient._testLogHistory.first)
        XCTAssertEqual("stripecore.downloadmanager.error", firstAnalytic["event"] as? String)
        XCTAssertEqual("failedToMakeImageFromData", firstAnalytic["error_code"] as? String)
        XCTAssertEqual("StripeCore.DownloadManager.Error", firstAnalytic["error_type"] as? String)
        XCTAssertEqual(self.validURL.absoluteString, firstAnalytic["url"] as? String)
    }

    // MARK: - Helper functions
    private func validImageData() -> Data {
        return generateUIImage(size: validImageSize).pngData()!
    }

    private func validImageData2() -> Data {
        return generateUIImage(size: validImageSize2).pngData()!
    }

    private func generateUIImage(size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.clear.set()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    struct NotFoundError: Error {}
}
