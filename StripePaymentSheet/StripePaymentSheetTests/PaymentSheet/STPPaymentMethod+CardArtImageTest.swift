//
//  STPPaymentMethod+CardArtImageTest.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) @testable import StripeCore
@_spi(STP) import StripeCoreTestUtils
import StripePaymentsObjcTestUtils
import XCTest

final class STPPaymentMethodCardArtImageTest: APIStubbedTestCase {

    var urlSessionConfig: URLSessionConfiguration!
    var downloadManager: DownloadManager!

    override func setUp() {
        super.setUp()
        urlSessionConfig = APIStubbedTestCase.stubbedURLSessionConfig()
        urlSessionConfig.urlCache = URLCache(memoryCapacity: 5_000_000, diskCapacity: 0)
        downloadManager = DownloadManager(urlSessionConfiguration: urlSessionConfig)
        downloadManager.resetCache()
    }

    // MARK: - STPPaymentMethod.cardArtImage

    func testCardArtImage_returnsNilWhenCardArtDisabled() {
        let pm = STPPaymentMethod._testCardWithCardArt()
        XCTAssertNil(pm.cachedCardArtImage(cardArtEnabled: false, downloadManager: downloadManager))
    }

    func testCardArtImage_returnsNilWhenNoCardArt() {
        let pm = STPPaymentMethod._testCard()
        XCTAssertNil(pm.cachedCardArtImage(cardArtEnabled: true, downloadManager: downloadManager))
    }

    func testCardArtImage_returnsNilWhenImageNotCached() {
        let pm = STPPaymentMethod._testCardWithCardArt()
        XCTAssertNil(pm.cachedCardArtImage(cardArtEnabled: true, downloadManager: downloadManager))
    }

    func testCardArtImage_returnsImageWhenCached() {
        let pm = STPPaymentMethod._testCardWithCardArt()
        let cardArtURL = pm.cardArtCDNURL(cardArtEnabled: true)!

        // Pre-seed the URL cache so downloadImage returns the real image
        let imageData = generateUIImage(size: CGSize(width: 100, height: 26)).pngData()!
        seedURLCache(url: cardArtURL, data: imageData)

        let result = pm.cachedCardArtImage(cardArtEnabled: true, downloadManager: downloadManager)
        XCTAssertNotNil(result)

        // The returned image should be the same as the one we created
        XCTAssertEqual(result?.size, CGSize(width: 100, height: 26))
    }

    // MARK: - Helpers

    private func seedURLCache(url: URL, data: Data) {
        let request = URLRequest(url: url)
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let cachedResponse = CachedURLResponse(response: response, data: data)
        urlSessionConfig.urlCache?.storeCachedResponse(cachedResponse, for: request)
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
}
