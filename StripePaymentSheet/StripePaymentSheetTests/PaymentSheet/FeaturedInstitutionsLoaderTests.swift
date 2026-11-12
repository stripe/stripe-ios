//
//  FeaturedInstitutionsLoaderTests.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@_spi(InternalOnlyAPI) @testable import StripePaymentSheet
import XCTest

@MainActor
final class FeaturedInstitutionsLoaderTests: APIStubbedTestCase {

    private let analyticsClient = STPAnalyticsClient()

    func testShouldFetch_onlyWithBankRow() {
        let elementsSession = STPElementsSession._testValue()
        XCTAssertTrue(FeaturedInstitutionsLoader.shouldFetch(elementsSession: elementsSession, paymentMethodTypes: [.stripe(.card), .instantDebits]))
        XCTAssertTrue(FeaturedInstitutionsLoader.shouldFetch(elementsSession: elementsSession, paymentMethodTypes: [.linkCardBrand]))
        XCTAssertFalse(FeaturedInstitutionsLoader.shouldFetch(elementsSession: elementsSession, paymentMethodTypes: [.stripe(.card), .stripe(.USBankAccount)]))
    }

    func testShouldFetch_killswitch() {
        // Given the killswitch is on, then nothing is fetched even with a Bank row
        let killswitchOn = STPElementsSession._testValue(flags: ["elements_mobile_featured_institutions_killswitch": true])
        XCTAssertFalse(FeaturedInstitutionsLoader.shouldFetch(elementsSession: killswitchOn, paymentMethodTypes: [.stripe(.card), .instantDebits]))

        // Given the killswitch is explicitly off, then the Bank row's icons are fetched
        let killswitchOff = STPElementsSession._testValue(flags: ["elements_mobile_featured_institutions_killswitch": false])
        XCTAssertTrue(FeaturedInstitutionsLoader.shouldFetch(elementsSession: killswitchOff, paymentMethodTypes: [.stripe(.card), .instantDebits]))
    }

    func testFetch_keepsOnlyInstitutionsWithIcons() async {
        // Given 5 institutions with icons and 2 without
        var requestQuery: [String: String] = [:]
        stubFeaturedInstitutions(
            institutions: (0..<5).map { makeInstitution(index: $0) } + [
                makeInstitution(index: 5, iconURL: nil),
                makeInstitution(index: 6, iconURL: ""),
            ],
            onRequest: { requestQuery = $0 }
        )
        stubIcons(failingIndices: [])

        // When
        let loader = makeLoader()
        loader.fetch()
        let icons = await loader.loadedIcons()

        // Then only the institutions with icons are kept...
        XCTAssertEqual(icons.count, 5)
        // ...and the request matches Stripe.js
        XCTAssertEqual(requestQuery["product"], "instant_debits")
        XCTAssertEqual(requestQuery["country"], "US")
        XCTAssertEqual(requestQuery["limit"], "12")
    }

    func testFetch_dropsIconsThatFailToDownload() async {
        // Given 5 institutions, one of which has an icon that fails to download
        stubFeaturedInstitutions(institutions: (0..<5).map { makeInstitution(index: $0) })
        stubIcons(failingIndices: [2])

        // When
        let loader = makeLoader()
        loader.fetch()
        let icons = await loader.loadedIcons()

        // Then
        XCTAssertEqual(icons.count, 4)
    }

    func testFetch_publishesIconsBeforeRotatingIconsFinish() async throws {
        // Given 5 institutions, where the last icon (only used by the rotating slot) downloads slowly
        stubFeaturedInstitutions(institutions: (0..<5).map { makeInstitution(index: $0) })
        stubIcons(failingIndices: [], slowIndices: [4])

        // When
        let loader = makeLoader()
        loader.fetch()
        for _ in 0..<100 where loader.icons.isEmpty {
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        // Then the first 4 icons are published without waiting for the slow one...
        XCTAssertEqual(loader.icons.count, 4)
        // ...and all 5 are published once it finishes
        let icons = await loader.loadedIcons()
        XCTAssertEqual(icons.count, 5)
    }

    func testFetch_fewerThanMinimumIcons_showsNothing() async {
        // Given only 3 institutions with icons
        stubFeaturedInstitutions(institutions: (0..<3).map { makeInstitution(index: $0) })
        stubIcons(failingIndices: [])

        // When
        let loader = makeLoader()
        loader.fetch()
        let icons = await loader.loadedIcons()

        // Then no icons are shown...
        XCTAssertTrue(icons.isEmpty)
        // ...and the shortfall is logged
        let event = analyticsClient._testLogHistory.last { $0["event"] as? String == "mc_instant_debits_featured_institutions_insufficient" }
        XCTAssertEqual(event?["count"] as? Int, 3)
    }

    func testFetch_requestFails_showsNothing() async {
        // Given the request fails
        stub(condition: isPath("/v1/connections/featured_institutions")) { _ in
            return HTTPStubsResponse(jsonObject: ["error": ["message": "Something went wrong"]], statusCode: 500, headers: nil)
        }

        // When
        let loader = makeLoader()
        loader.fetch()
        let icons = await loader.loadedIcons()

        // Then no icons are shown...
        XCTAssertTrue(icons.isEmpty)
        // ...and the failure is logged
        XCTAssertTrue(analyticsClient._testLogHistory.contains { $0["event"] as? String == "mc_instant_debits_featured_institutions_load_failed" })
    }

    func testPreloadedIcons_belowMinimum_showsNothing() {
        XCTAssertTrue(FeaturedInstitutionsLoader(icons: [UIImage(), UIImage()]).icons.isEmpty)
        XCTAssertEqual(FeaturedInstitutionsLoader(icons: Array(repeating: UIImage(), count: 4)).icons.count, 4)
    }

    // MARK: - Helpers

    private func makeLoader() -> FeaturedInstitutionsLoader {
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_123"
        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = apiClient
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .embedded, configuration: configuration, analyticsClient: analyticsClient)
        // Use a memory-only cache to isolate tests from each other
        let urlSessionConfig = APIStubbedTestCase.stubbedURLSessionConfig()
        urlSessionConfig.urlCache = URLCache(memoryCapacity: 5_000_000, diskCapacity: 0)
        let downloadManager = DownloadManager(urlSessionConfiguration: urlSessionConfig, analyticsClient: analyticsClient, isTesting: true)
        return FeaturedInstitutionsLoader(apiClient: apiClient, analyticsHelper: analyticsHelper, downloadManager: downloadManager)
    }

    private func makeInstitution(index: Int, iconURL: String? = "default") -> [String: Any] {
        var institution: [String: Any] = [
            "id": "bank_\(index)",
            "name": "Bank \(index)",
            "featured": true,
        ]
        if let iconURL {
            institution["icon"] = ["default": iconURL == "default" ? "https://b.stripecdn.com/icons/bank_\(index).png" : iconURL]
        }
        return institution
    }

    private func stubFeaturedInstitutions(institutions: [[String: Any]], onRequest: (([String: String]) -> Void)? = nil) {
        stub(condition: isPath("/v1/connections/featured_institutions")) { request in
            let queryItems = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
            onRequest?(Dictionary(queryItems.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { first, _ in first }))
            return HTTPStubsResponse(
                jsonObject: ["object": "list", "data": institutions, "has_more": false],
                statusCode: 200,
                headers: nil
            )
        }
    }

    private func stubIcons(failingIndices: Set<Int>, slowIndices: Set<Int> = []) {
        let imageData = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }.pngData()!
        stub(condition: isHost("b.stripecdn.com")) { request in
            let isFailing = failingIndices.contains { request.url?.lastPathComponent == "bank_\($0).png" }
            guard !isFailing else {
                return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist))
            }
            let isSlow = slowIndices.contains { request.url?.lastPathComponent == "bank_\($0).png" }
            return HTTPStubsResponse(data: imageData, statusCode: 200, headers: nil).responseTime(isSlow ? 2 : 0)
        }
    }
}
