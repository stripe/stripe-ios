//
//  PMMENetworkInitializationTests.swift
//  StripePaymentSheet
//
//  Created by George Birch on 11/10/25.
//

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP)@testable import StripeCore
import StripeCoreTestUtils
@_spi(STP)@testable import StripePaymentSheet
@_spi(STP)@testable import StripePaymentsTestUtils
import XCTest

class PMMENetworkInitializationTests: STPNetworkStubbingTestCase {

    // Test publishable keys
    static let usPublishableKey = "pk_test_51HvTI7Lu5o3P18Zp6t5AgBSkMvWoTtA0nyA7pVYDqpfLkRtWun7qZTYCOHCReprfLM464yaBeF72UFfB7cY9WG4a00ZnDtiC2C"
    static let frenchPublishableKey = "pk_test_51JtgfQKG6vc7r7YCU0qQNOkDaaHrEgeHgGKrJMNfuWwaKgXMLzPUA1f8ZlCNPonIROLOnzpUnJK1C1xFH3M3Mz8X00Q6O4GfUt"
    static let usConnectedAccountId = "acct_1SSPcCLmk7lnVRaw"

    var downloadManager: DownloadManager!
    var apiClient: STPAPIClient!

    override func setUp() {
        super.setUp()

        // Create a DownloadManager with the shared URLSession configuration
        // This allows the network stubbing recorder to intercept API requests
        let urlSessionConfig = StripeAPIConfiguration.sharedUrlSessionConfiguration
        downloadManager = DownloadManager(urlSessionConfiguration: urlSessionConfig)
        downloadManager.resetCache()

        // Create an STPAPIClient with the US test publishable key
        apiClient = STPAPIClient(publishableKey: Self.usPublishableKey)

        // Stub image downloads to return local mock PNG files
        // Note: These will still be recorded in .tail files, but we use the stubs to run the tests
        //      because PMME fetches the images concurrently/in arbitrary order, so the ordered tail
        //      file approach doesn't work for this purpose.
        setupImageStubs()
    }

    // MARK: - Tests

    func testCreate_multiPartner_automatic() async {
        // Given: A configuration with automatic style
        let appearance = PaymentMethodMessagingElement.Appearance()
        let configuration = PaymentMethodMessagingElement.Configuration(
            amount: 5000,
            currency: "usd",
            apiClient: apiClient,
            appearance: appearance
        )

        // When: Creating the element
        let result = await PaymentMethodMessagingElement.create(
            configuration: configuration,
            downloadManager: downloadManager
        )

        // Then: Verify success and correct ViewData
        guard case .success(let pmme) = result else {
            XCTFail("Expected success, got \(result)")
            return
        }

        let actualViewData = pmme.viewData

        let expectedViewData = PaymentMethodMessagingElement.ViewData(
            mode: .multiPartner(logos: [
                .init(
                    light: loadTestImage("cashapp-afterpay-logo"),
                    dark: loadTestImage("cashapp-afterpay-logo-dark"),
                    altText: "Cash App Afterpay"
                ),
                .init(
                    light: loadTestImage("affirm-logo"),
                    dark: loadTestImage("affirm-logo-dark"),
                    altText: "Affirm"
                ),
                .init(
                    light: loadTestImage("klarna-logo"),
                    dark: loadTestImage("klarna-logo-dark"),
                    altText: "Klarna"
                ),
            ]),
            infoUrl: URL(string: "https://b.stripecdn.com/payment-method-messaging-statics-srv/assets/learn-more/index.html?amount=5000&country=US&currency=USD&key=\(Self.usPublishableKey)&locale=en&payment_methods%5B0%5D=afterpay_clearpay&payment_methods%5B1%5D=affirm&payment_methods%5B2%5D=klarna&title=Learn%20more")!,
            promotion: "4 interest-free payments of $12.50",
            appearance: appearance
        )

        assertViewDataEqual(actualViewData, expectedViewData)
    }

    func testCreate_connectedAccount_singlePartner() async {
        // Given: A configuration using a connected account publishable key
        let appearance = PaymentMethodMessagingElement.Appearance()
        let connectedAPIClient = STPAPIClient(publishableKey: Self.usPublishableKey)
        connectedAPIClient.stripeAccount = Self.usConnectedAccountId
        let configuration = PaymentMethodMessagingElement.Configuration(
            amount: 5000,
            currency: "usd",
            apiClient: connectedAPIClient,
            appearance: appearance
        )

        // When: Creating the element
        let result = await PaymentMethodMessagingElement.create(
            configuration: configuration,
            downloadManager: downloadManager
        )

        // Then: Verify success with single partner
        // It should be Affirm only, becuase that is what is enabled in the connected account, even though all are enabled
        guard case .success(let pmme) = result else {
            XCTFail("Expected success, got \(result)")
            return
        }

        let actualViewData = pmme.viewData

        let expectedViewData = PaymentMethodMessagingElement.ViewData(
            mode: .singlePartner(logo: .init(
                light: loadTestImage("affirm-logo"),
                dark: loadTestImage("affirm-logo-dark"),
                altText: "Affirm"
            )),
            infoUrl: URL(string: "https://b.stripecdn.com/payment-method-messaging-statics-srv/assets/learn-more/index.html?amount=5000&country=US&currency=USD&key=\(Self.usPublishableKey)&locale=en&payment_methods%5B0%5D=affirm&title=Learn%20more")!,
            promotion: "4 interest-free payments of $12.50 with {partner}",
            appearance: appearance
        )

        assertViewDataEqual(actualViewData, expectedViewData)
    }

    func testCreate_multiPartner_alwaysDark() async {
        // Given: A configuration with alwaysDark style
        let appearance = PaymentMethodMessagingElement.Appearance(style: .alwaysDark)
        let configuration = PaymentMethodMessagingElement.Configuration(
            amount: 5000,
            currency: "usd",
            apiClient: apiClient,
            appearance: appearance
        )

        // When: Creating the element
        let result = await PaymentMethodMessagingElement.create(
            configuration: configuration,
            downloadManager: downloadManager
        )

        // Then: Verify success and correct ViewData
        guard case .success(let pmme) = result else {
            XCTFail("Expected success, got \(result)")
            return
        }

        let actualViewData = pmme.viewData

        // For alwaysDark style, both light and dark should use the dark image
        let darkImage1 = loadTestImage("cashapp-afterpay-logo-dark")
        let darkImage2 = loadTestImage("affirm-logo-dark")
        let darkImage3 = loadTestImage("klarna-logo-dark")

        let expectedViewData = PaymentMethodMessagingElement.ViewData(
            mode: .multiPartner(logos: [
                .init(
                    light: darkImage1,
                    dark: darkImage1,
                    altText: "Cash App Afterpay"
                ),
                .init(
                    light: darkImage2,
                    dark: darkImage2,
                    altText: "Affirm"
                ),
                .init(
                    light: darkImage3,
                    dark: darkImage3,
                    altText: "Klarna"
                ),
            ]),
            infoUrl: URL(string: "https://b.stripecdn.com/payment-method-messaging-statics-srv/assets/learn-more/index.html?amount=5000&country=US&currency=USD&key=\(Self.usPublishableKey)&locale=en&payment_methods%5B0%5D=afterpay_clearpay&payment_methods%5B1%5D=affirm&payment_methods%5B2%5D=klarna&title=Learn%20more")!,
            promotion: "4 interest-free payments of $12.50",
            appearance: appearance
        )

        assertViewDataEqual(actualViewData, expectedViewData)
    }

    func testCreate_multiPartner_flat() async {
        // Given: A configuration with flat style
        let appearance = PaymentMethodMessagingElement.Appearance(style: .flat)
        let configuration = PaymentMethodMessagingElement.Configuration(
            amount: 5000,
            currency: "usd",
            apiClient: apiClient,
            appearance: appearance
        )

        // When: Creating the element
        let result = await PaymentMethodMessagingElement.create(
            configuration: configuration,
            downloadManager: downloadManager
        )

        // Then: Verify success and correct ViewData
        guard case .success(let pmme) = result else {
            XCTFail("Expected success, got \(result)")
            return
        }

        let actualViewData = pmme.viewData

        // For flat style, both light and dark should use the flat image
        let flatImage1 = loadTestImage("cashapp-afterpay-logo-flat")
        let flatImage2 = loadTestImage("affirm-logo-flat")
        let flatImage3 = loadTestImage("klarna-logo-flat")

        let expectedViewData = PaymentMethodMessagingElement.ViewData(
            mode: .multiPartner(logos: [
                .init(
                    light: flatImage1,
                    dark: flatImage1,
                    altText: "Cash App Afterpay"
                ),
                .init(
                    light: flatImage2,
                    dark: flatImage2,
                    altText: "Affirm"
                ),
                .init(
                    light: flatImage3,
                    dark: flatImage3,
                    altText: "Klarna"
                ),
            ]),
            infoUrl: URL(string: "https://b.stripecdn.com/payment-method-messaging-statics-srv/assets/learn-more/index.html?amount=5000&country=US&currency=USD&key=\(Self.usPublishableKey)&locale=en&payment_methods%5B0%5D=afterpay_clearpay&payment_methods%5B1%5D=affirm&payment_methods%5B2%5D=klarna&title=Learn%20more")!,
            promotion: "4 interest-free payments of $12.50",
            appearance: appearance
        )

        assertViewDataEqual(actualViewData, expectedViewData)
    }

    func testCreate_singlePartner() async {
        // Given: A configuration with only one payment method (Klarna)
        let appearance = PaymentMethodMessagingElement.Appearance()
        var configuration = PaymentMethodMessagingElement.Configuration(
            amount: 5000,
            currency: "usd",
            apiClient: apiClient,
            appearance: appearance
        )
        configuration.paymentMethodTypes = [.klarna]

        // When: Creating the element
        let result = await PaymentMethodMessagingElement.create(
            configuration: configuration,
            downloadManager: downloadManager
        )

        // Then: Verify success and correct ViewData with single partner
        guard case .success(let pmme) = result else {
            XCTFail("Expected success, got \(result)")
            return
        }

        let actualViewData = pmme.viewData

        let expectedViewData = PaymentMethodMessagingElement.ViewData(
            mode: .singlePartner(logo: .init(
                light: loadTestImage("klarna-logo"),
                dark: loadTestImage("klarna-logo-dark"),
                altText: "Klarna"
            )),
            infoUrl: URL(string: "https://b.stripecdn.com/payment-method-messaging-statics-srv/assets/learn-more/index.html?amount=5000&country=US&currency=USD&key=\(Self.usPublishableKey)&locale=en&payment_methods%5B0%5D=klarna&title=Learn%20more")!,
            promotion: "4 interest-free payments of $12.50 with {partner}",
            appearance: appearance
        )

        assertViewDataEqual(actualViewData, expectedViewData)
    }

    func testCreate_invalidCurrency() async {
        // Given: A configuration with an invalid currency code
        let appearance = PaymentMethodMessagingElement.Appearance()
        let configuration = PaymentMethodMessagingElement.Configuration(
            amount: 5000,
            currency: "gel",  // Georgian Lari - supported by Stripe but not PMME
            apiClient: apiClient,
            appearance: appearance
        )

        // When: Creating the element
        let result = await PaymentMethodMessagingElement.create(
            configuration: configuration,
            downloadManager: downloadManager
        )

        // Then: Verify we get a failure result
        // When the API returns an error response (e.g., with error status code),
        //      it should be caught by the StripeAPIClient and passed through as a failure
        guard case .failed(let error) = result else {
            XCTFail("Expected failure for invalid currency, got success")
            return
        }

        guard let stripeError = error as? StripeError,
              case let .apiError(apiError) = stripeError else {
            XCTFail("Expected .apiError, got \(String(describing: error))")
            return
        }

        XCTAssertEqual(apiError.param, "currency")
        XCTAssertEqual(apiError.message, "unsupported_currency: gel")
    }

    func testCreate_invalidCountry() async {
        // Given: A configuration with an invalid country code
        let appearance = PaymentMethodMessagingElement.Appearance()
        var configuration = PaymentMethodMessagingElement.Configuration(
            amount: 5000,
            currency: "usd",
            apiClient: apiClient,
            appearance: appearance
        )
        configuration.countryCode = "ZZ"  // Invalid country code

        // When: Creating the element
        let result = await PaymentMethodMessagingElement.create(
            configuration: configuration,
            downloadManager: downloadManager
        )

        // Then: Verify we get a failure result with proper error details
        guard case .failed(let error) = result else {
            XCTFail("Expected failure for invalid country, got success")
            return
        }

        guard let stripeError = error as? StripeError,
              case let .apiError(apiError) = stripeError else {
            XCTFail("Expected .apiError, got \(String(describing: error))")
            return
        }

        XCTAssertEqual(apiError.param, "country")
        XCTAssertEqual(apiError.message, "nonexistent_country: ZZ")
    }

    func testCreate_negativeAmount() async {
        // Given: A configuration with a negative amount
        let appearance = PaymentMethodMessagingElement.Appearance()
        let configuration = PaymentMethodMessagingElement.Configuration(
            amount: -1000,
            currency: "usd",
            apiClient: apiClient,
            appearance: appearance
        )

        // When: Creating the element
        let result = await PaymentMethodMessagingElement.create(
            configuration: configuration,
            downloadManager: downloadManager
        )

        // Then: Verify we get no content
        // Negative amounts are invalid but the API may return a successful empty response
        guard case .noContent = result else {
            XCTFail("Expected .noContent for negative amount, got \(result)")
            return
        }
    }

    func testCreate_missingPublishableKey() async {
        // Given: A configuration with an API client that has no publishable key
        let appearance = PaymentMethodMessagingElement.Appearance()
        let invalidAPIClient = STPAPIClient()
        let configuration = PaymentMethodMessagingElement.Configuration(
            amount: 5000,
            currency: "usd",
            apiClient: invalidAPIClient,
            appearance: appearance
        )

        // When: Creating the element
        let result = await PaymentMethodMessagingElement.create(
            configuration: configuration,
            downloadManager: downloadManager
        )

        // Then: Verify we get a failure with the specific missingPublishableKey error
        guard case .failed(let error) = result else {
            XCTFail("Expected failure for missing publishable key, got success")
            return
        }

        guard let pmmeError = error as? PaymentMethodMessagingElementError,
              case .missingPublishableKey = pmmeError else {
            XCTFail("Expected PaymentMethodMessagingElementError.missingPublishableKey, got \(String(describing: error))")
            return
        }
    }

    func testCreate_countryFrance_currencyUSD() async {
        // Given: A configuration with France as country but USD as currency
        let appearance = PaymentMethodMessagingElement.Appearance()
        var configuration = PaymentMethodMessagingElement.Configuration(
            amount: 5000,
            currency: "usd",
            apiClient: apiClient,
            appearance: appearance
        )
        configuration.countryCode = "FR"

        // When: Creating the element
        let result = await PaymentMethodMessagingElement.create(
            configuration: configuration,
            downloadManager: downloadManager
        )

        // Then: Verify we get no content
        // Country/currency mismatches typically result in no available payment methods
        guard case .noContent = result else {
            XCTFail("Expected .noContent for France/USD combination, got \(result)")
            return
        }
    }

    func testCreate_countryFrance_currencyEUR() async {
        // Given: A configuration with France as country and EUR as currency (matching pair)
        // using a French publishable key to get proper payment method availability
        let appearance = PaymentMethodMessagingElement.Appearance()
        let frenchAPIClient = STPAPIClient(publishableKey: Self.frenchPublishableKey)
        var configuration = PaymentMethodMessagingElement.Configuration(
            amount: 5000,
            currency: "eur",
            apiClient: frenchAPIClient,
            appearance: appearance
        )
        configuration.countryCode = "FR"

        // When: Creating the element
        let result = await PaymentMethodMessagingElement.create(
            configuration: configuration,
            downloadManager: downloadManager
        )

        // Then: Verify success with French market payment methods
        guard case .success(let pmme) = result else {
            XCTFail("Expected success for France/EUR combination with French key, got \(result)")
            return
        }

        let actualViewData = pmme.viewData

        // Based on European payment method availability, we expect Klarna
        let expectedViewData = PaymentMethodMessagingElement.ViewData(
            mode: .singlePartner(logo: .init(
                light: loadTestImage("klarna-logo"),
                dark: loadTestImage("klarna-logo-dark"),
                altText: "Klarna"
            )),
            infoUrl: URL(string: "https://b.stripecdn.com/payment-method-messaging-statics-srv/assets/learn-more/index.html?amount=5000&country=FR&currency=EUR&key=\(Self.frenchPublishableKey)&locale=en&payment_methods%5B0%5D=klarna&title=Learn%20more")!,
            promotion: "3 interest-free payments of €16.67 with {partner}",
            appearance: appearance
        )

        assertViewDataEqual(actualViewData, expectedViewData)
    }

    func testCreate_localeFrench() async {
        // Given: A configuration with French locale
        let appearance = PaymentMethodMessagingElement.Appearance()
        var configuration = PaymentMethodMessagingElement.Configuration(
            amount: 5000,
            currency: "usd",
            apiClient: apiClient,
            appearance: appearance
        )
        configuration.locale = "fr"  // French locale

        // When: Creating the element
        let result = await PaymentMethodMessagingElement.create(
            configuration: configuration,
            downloadManager: downloadManager
        )

        // Then: Verify success with French-localized messaging but still US/USD info
        guard case .success(let pmme) = result else {
            XCTFail("Expected success for French locale, got \(result)")
            return
        }

        let actualViewData = pmme.viewData

        let expectedViewData = PaymentMethodMessagingElement.ViewData(
            mode: .multiPartner(logos: [
                .init(
                    light: loadTestImage("cashapp-afterpay-logo"),
                    dark: loadTestImage("cashapp-afterpay-logo-dark"),
                    altText: "Cash App Afterpay"
                ),
                .init(
                    light: loadTestImage("affirm-logo"),
                    dark: loadTestImage("affirm-logo-dark"),
                    altText: "Affirm"
                ),
                .init(
                    light: loadTestImage("klarna-logo"),
                    dark: loadTestImage("klarna-logo-dark"),
                    altText: "Klarna"
                ),
            ]),
            infoUrl: URL(string: "https://b.stripecdn.com/payment-method-messaging-statics-srv/assets/learn-more/index.html?amount=5000&country=US&currency=USD&key=\(Self.usPublishableKey)&locale=fr&payment_methods%5B0%5D=afterpay_clearpay&payment_methods%5B1%5D=affirm&payment_methods%5B2%5D=klarna&title=En%20savoir%20plus")!,
            promotion: "4 paiements de 12,50 $US sans intérêts",
            appearance: appearance
        )

        assertViewDataEqual(actualViewData, expectedViewData)
    }

    // MARK: - Helper Methods

    /// Compares two ViewData instances, comparing UIImages by their PNG data instead of identity
    /// - Parameters:
    ///   - actual: The actual ViewData to compare
    ///   - expected: The expected ViewData to compare against
    ///   - file: The file where the assertion is made (for better error reporting)
    ///   - line: The line where the assertion is made (for better error reporting)
    private func assertViewDataEqual(
        _ actual: PaymentMethodMessagingElement.ViewData,
        _ expected: PaymentMethodMessagingElement.ViewData,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Compare promotion text
        XCTAssertEqual(actual.promotion, expected.promotion, "Promotion text mismatch", file: file, line: line)

        // Compare info URL
        XCTAssertEqual(actual.infoUrl, expected.infoUrl, "Info URL mismatch", file: file, line: line)

        // Compare appearance
        XCTAssertEqual(actual.appearance, expected.appearance, "Appearance mismatch", file: file, line: line)

        // Compare mode with custom logo comparison
        switch (actual.mode, expected.mode) {
        case (.singlePartner(let actualLogo), .singlePartner(let expectedLogo)):
            assertLogoSetEqual(actualLogo, expectedLogo, file: file, line: line)

        case (.multiPartner(let actualLogos), .multiPartner(let expectedLogos)):
            XCTAssertEqual(actualLogos.count, expectedLogos.count, "Logo count mismatch", file: file, line: line)
            for (index, (actualLogo, expectedLogo)) in zip(actualLogos, expectedLogos).enumerated() {
                assertLogoSetEqual(actualLogo, expectedLogo, index: index, file: file, line: line)
            }

        default:
            XCTFail("Mode mismatch: actual=\(actual.mode), expected=\(expected.mode)", file: file, line: line)
        }
    }

    /// Compares two LogoSet instances by comparing UIImage content using PNG data
    private func assertLogoSetEqual(
        _ actual: PaymentMethodMessagingElement.LogoSet,
        _ expected: PaymentMethodMessagingElement.LogoSet,
        index: Int? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let prefix = index.map { "Logo[\($0)]" } ?? "Logo"

        // Compare alt text
        XCTAssertEqual(actual.altText, expected.altText, "\(prefix) alt text mismatch", file: file, line: line)

        // Compare light and dark images using .pngData()
        XCTAssertTrue(actual.light.pngData() == expected.light.pngData(), "\(prefix).light image mismatch", file: file, line: line)
        XCTAssertTrue(actual.dark.pngData() == expected.dark.pngData(), "\(prefix).dark image mismatch", file: file, line: line)
    }

    /// Sets up HTTP stubs to return local PNG files for image downloads
    /// The stub matches URLs and returns the corresponding PNG file from MockFiles/PMMELogos/
    /// based on the filename in the URL path
    private func setupImageStubs() {
        stub(condition: { request in
            // Match any request that looks like an image URL
            guard let url = request.url,
                  let pathComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)?.path else {
                return false
            }

            // Check if it's a PNG file request
            return pathComponents.hasSuffix(".png")
        }) { request in
            guard let url = request.url,
                  let filename = url.pathComponents.last else {
                return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist))
            }

            // Load the corresponding PNG file from the test bundle
            guard let imageData = self.loadMockImage(filename: filename) else {
                return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist))
            }

            return HTTPStubsResponse(data: imageData, statusCode: 200, headers: ["Content-Type": "image/png"])
        }
    }

    /// Loads a mock PNG file from the test bundle's MockFiles/PMME directory
    /// - Parameter filename: The name of the PNG file (e.g., "klarna-logo.png")
    /// - Returns: The PNG data, or nil if the file doesn't exist
    private func loadMockImage(filename: String) -> Data? {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "MockFiles/PMME/\(filename.replacingOccurrences(of: ".png", with: ""))", withExtension: "png") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }

    /// Loads a UIImage using the existing loadMockImage helper
    /// - Parameter filename: The name of the PNG file (without extension)
    /// - Returns: The UIImage, or fails the test if the image can't be loaded
    private func loadTestImage(_ filename: String, file: StaticString = #file, line: UInt = #line) -> UIImage {
        guard let imageData = loadMockImage(filename: filename),
              let image = UIImage(data: imageData, scale: 3.0) else {
            XCTFail("Could not load image: \(filename).png", file: file, line: line)
            return UIImage()
        }
        return image
    }
}
