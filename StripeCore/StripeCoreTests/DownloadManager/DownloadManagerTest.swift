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

    override func setUp() {
        super.setUp()
        self.urlSessionConfig = APIStubbedTestCase.stubbedURLSessionConfig()
        self.rm = DownloadManager(urlSessionConfiguration: urlSessionConfig)

        self.rm.resetDiskCache()
        self.rm.resetMemoryCache()
    }

    func testSynchronous_validImage() {
        stub(condition: { request in
            return request.url?.path.contains("/validImage.png") ?? false
        }) { _ in
            return HTTPStubsResponse(data: self.validImageData(), statusCode: 200, headers: nil)
        }

        let image = rm.downloadImage(url: validURL, updateHandler: nil)
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

        let image = rm.downloadImage(url: validURL, updateHandler: nil)
        XCTAssertEqual(image.size, validImageSize)

        wait(for: [expectedRequest], timeout: 1.0)

        let cachedImageWithoutNetworkCall = rm.downloadImage(url: validURL, updateHandler: nil)
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

        let image = rm.downloadImage(url: validURL, updateHandler: nil)
        XCTAssertEqual(image.size, validImageSize)
        wait(for: [expectedRequest1], timeout: 1.0)

        rm.resetDiskCache()
        rm.resetMemoryCache()

        let cachedImageWithoutNetworkCall = rm.downloadImage(url: validURL, updateHandler: nil)
        XCTAssertEqual(cachedImageWithoutNetworkCall.size, validImageSize)
        wait(for: [expectedRequest2], timeout: 1.0)
    }

    func testSynchronous_invalidImage() {
        stub(condition: { request in
            return request.url?.path.contains("/invalidImage.png") ?? false
        }) { _ in
            return HTTPStubsResponse(error: NotFoundError())
        }

        let image = rm.downloadImage(url: invalidURL, updateHandler: nil)

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
            url: validURL,
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
            url: validURL,
            updateHandler: { image in
                XCTAssertEqual(image.size, self.validImageSize)
                expected1.fulfill()
            }
        )

        XCTAssertEqual(image.size, placeholderImageSize)
        wait(for: [expected1], timeout: 1.0)

        let expected2 = expectation(
            description: "updateHandler will not be called when image is cached"
        )
        expected2.isInverted = true
        let imageCached = rm.downloadImage(
            url: validURL,
            updateHandler: { _ in
                expected2.fulfill()
            }
        )

        XCTAssertEqual(imageCached.size, validImageSize)
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
            url: validURL,
            updateHandler: { image in
                XCTAssertEqual(image.size, self.validImageSize)
                expected1.fulfill()
            }
        )

        XCTAssertEqual(image.size, placeholderImageSize)
        wait(for: [expected1], timeout: 1.0)

        rm.resetMemoryCache()
        rm.resetDiskCache()

        let expected2 = expectation(description: "updateHandler us called a second time")
        let image2 = rm.downloadImage(
            url: validURL,
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
            url: invalidURL,
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
            url: validURL,
            updateHandler: { cb_image1 in
                XCTAssertEqual(cb_image1.size, self.validImageSize)
                expected_imageUpdater1.fulfill()
                let image2 = self.rm.downloadImage(
                    url: self.validURL2,
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

    func testImageNamefromURL() {
        let img0 = rm.imageNameFromURL(url: URL(string: "http://js.stripe.com/icon0.png")!)
        XCTAssertEqual(img0, "icon0.png")

        let img1 = rm.imageNameFromURL(
            url: URL(string: "http://js.stripe.com/icon1.png?key1=value1")!
        )
        XCTAssertEqual(img1, "icon1.png")
    }

    func test_nil_AddUpdateHandlerWithoutLocking_unableToAddEmptyBlock() {
        rm.addUpdateHandlerWithoutLocking(nil, forImageName: "imgName1")
        XCTAssert(rm.updateHandlers.isEmpty)
    }

    func test_AddUpdateHandlerWithoutLocking_appends() {
        let expect1 = expectation(description: "first")
        let expect2 = expectation(description: "second")
        let updateHandler1: DownloadManager.UpdateImageHandler = { _ in expect1.fulfill() }
        let updateHandler2: DownloadManager.UpdateImageHandler = { _ in expect2.fulfill() }

        rm.addUpdateHandlerWithoutLocking(updateHandler1, forImageName: "imgName1")
        rm.addUpdateHandlerWithoutLocking(updateHandler2, forImageName: "imgName1")

        guard let firstHandler = rm.updateHandlers["imgName1"]?.first,
            let lastHandler = rm.updateHandlers["imgName1"]?.last
        else {
            XCTFail("Unable to get handlers")
            return
        }

        firstHandler(UIImage())
        lastHandler(UIImage())

        wait(for: [expect1], timeout: 1.0)
        wait(for: [expect2], timeout: 1.0)
    }

    func test_persistToMemory() {
        XCTAssertNil(rm.cachedImageNamed("imgName"))

        let validImageData = validImageData()
        guard let image = rm.persistToMemory(validImageData, forImageName: "imgName") else {
            XCTFail("Failed to persist to memory")
            return
        }

        XCTAssertEqual(image.size, validImageSize)
        XCTAssertNotNil(rm.imageCache["imgName"])
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
