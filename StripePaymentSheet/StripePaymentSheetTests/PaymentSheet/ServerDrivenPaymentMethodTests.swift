//
//  ServerDrivenPaymentMethodTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 11/10/26.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) @_spi(AppearanceAPIAdditionsPreview) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsTestUtils
@testable@_spi(InternalOnlyAPI) import StripeUICore

/// Described `payment_method_availability.payment_methods` entries for tests.
enum ServerDrivenPaymentMethodFixtures {
    /// Returns the URL of `name`'s icon at `scale`, like the server's content-hashed icon URLs.
    static func iconURL(_ name: String, scale: Int) -> URL {
        return URL(string: "https://b.stripecdn.com/ocs-mobile/assets/pm/ios/\(name)-\(scale)x-abc123.png")!
    }

    /// Returns an `IconImage` with a source at each of `scales`, at `iconURL(name, scale:)`.
    static func iconImageJSON(_ name: String, scales: [Int] = [2, 3]) -> [String: Any] {
        return ["sources": scales.map { ["url": iconURL(name, scale: $0).absoluteString, "scale": $0] as [String: Any] }]
    }

    /// Returns a described DemoPay entry. `modify` changes it.
    static func json(type: String = "demo_pay", _ modify: (inout [String: Any]) -> Void = { _ in }) -> [String: Any] {
        var json: [String: Any] = [
            "type": type,
            "display": [
                "label": "Demo Pay",
                "subtitle": "Pay with Demo Pay",
                "icon": [
                    "light": iconImageJSON(type),
                    "rendering": "original",
                ] as [String: Any],
            ] as [String: Any],
        ]
        modify(&json)
        return json
    }

    /// Decodes `json` the way the sidecar is decoded.
    static func entry(_ json: [String: Any] = json()) throws -> MobileSession.PaymentMethodEntry {
        let data = try JSONSerialization.data(withJSONObject: [
            "payment_method_availability": ["payment_methods": [json], "link_enabled": false] as [String: Any],
        ])
        return try XCTUnwrap(MobileSession.decode(data).paymentMethodAvailability?.paymentMethods.first)
    }

    static func serverDrivenPaymentMethod(_ json: [String: Any] = json()) throws -> ServerDrivenPaymentMethod {
        let entry = try entry(json)
        return try ServerDrivenPaymentMethod(type: entry.type, display: XCTUnwrap(entry.display))
    }

    /// Returns a DemoPay entry with light and dark icons, named `<type>` and `<type>_dark`.
    static func lightAndDarkJSON(type: String = "demo_pay", rendering: String = "template") -> [String: Any] {
        return json(type: type) {
            $0[jsonDict: "display"]?["icon"] = [
                "light": iconImageJSON(type),
                "dark": iconImageJSON("\(type)_dark"),
                "rendering": rendering,
            ] as [String: Any]
        }
    }

    /// Returns `scale`x PNG data for a 30x20pt icon, filled with `color`.
    static func iconData(scale: Int, color: UIColor = .systemIndigo) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = CGSize(width: 30 * scale, height: 20 * scale)
        return UIGraphicsImageRenderer(size: size, format: format).pngData { _ in
            color.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: CGFloat(4 * scale)).fill()
        }
    }
}

@MainActor
class ServerDrivenPaymentMethodTests: XCTestCase {

    func testInit_mapsEntry() throws {
        // When a DemoPay entry is mapped
        let paymentMethod = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod()

        // Then it keeps the type and display values
        XCTAssertEqual(paymentMethod.type, "demo_pay")
        XCTAssertEqual(paymentMethod.label, "Demo Pay")
        XCTAssertEqual(paymentMethod.subtitle, "Pay with Demo Pay")
        XCTAssertEqual(paymentMethod.icon.light.sources, [
            .init(url: ServerDrivenPaymentMethodFixtures.iconURL("demo_pay", scale: 2), scale: 2),
            .init(url: ServerDrivenPaymentMethodFixtures.iconURL("demo_pay", scale: 3), scale: 3),
        ])
        XCTAssertNil(paymentMethod.icon.dark)
        XCTAssertFalse(paymentMethod.icon.isTemplate)
    }

    func testInit_throwsForValuesItCantRender() throws {
        // Each entry has one value this SDK can't render, and throws that value
        let cases: [(String, (inout [String: Any]) -> Void)] = [
            ("icon_rendering:unparsable", { $0[jsonDict: "display"]?[jsonDict: "icon"]?["rendering"] = "vector" }),
            ("icon:invalid_url", { $0[jsonDict: "display"]?[jsonDict: "icon"]?["light"] = ["sources": [["url": "http://js.stripe.com/icon.png", "scale": 2]]] }),
            ("icon:invalid_url", { $0[jsonDict: "display"]?[jsonDict: "icon"]?["dark"] = ["sources": [["url": "", "scale": 2]]] }),
            ("icon:invalid_scale", { $0[jsonDict: "display"]?[jsonDict: "icon"]?["light"] = ["sources": [["url": "https://js.stripe.com/icon.png", "scale": 0]]] }),
            ("icon:no_sources", { $0[jsonDict: "display"]?[jsonDict: "icon"]?["light"] = ["sources": [] as [Any]] }),
            ("type:empty", { $0["type"] = "" }),
        ]
        for (expectedValue, modify) in cases {
            let entry = try ServerDrivenPaymentMethodFixtures.entry(ServerDrivenPaymentMethodFixtures.json(modify))
            XCTAssertThrowsError(try ServerDrivenPaymentMethod(type: entry.type, display: XCTUnwrap(entry.display)), expectedValue) { error in
                XCTAssertEqual(error as? ServerDrivenPaymentMethod.UnsupportedValue, .init(value: expectedValue))
            }
        }
    }

    func testIconSource_picksSmallestScaleAtOrAboveScreenScale() {
        func image(_ scales: [Int]) -> ServerDrivenPaymentMethod.Icon.Image {
            return .init(sources: scales.map { .init(url: ServerDrivenPaymentMethodFixtures.iconURL("demo_pay", scale: $0), scale: $0) })
        }
        // Given 2x and 3x sources, a 2x and a 3x screen each get their own scale
        XCTAssertEqual(image([2, 3]).source(forScreenScale: 2).scale, 2)
        XCTAssertEqual(image([2, 3]).source(forScreenScale: 3).scale, 3)
        // ...a 1x screen gets the smallest source above it
        XCTAssertEqual(image([2, 3]).source(forScreenScale: 1).scale, 2)
        // ...and a screen above every source gets the largest
        XCTAssertEqual(image([2, 3]).source(forScreenScale: 4).scale, 3)

        // Given a missing scale, a 3x screen with only 2x gets 2x, and a 2x screen with only 3x gets 3x
        XCTAssertEqual(image([2]).source(forScreenScale: 3).scale, 2)
        XCTAssertEqual(image([3]).source(forScreenScale: 2).scale, 3)
        // ...whatever order the sources are in
        XCTAssertEqual(image([3, 1, 2]).source(forScreenScale: 1.5).url, ServerDrivenPaymentMethodFixtures.iconURL("demo_pay", scale: 2))
    }

    func testIcon_picksDarkForDarkBackground() throws {
        // Given an icon with light and dark images
        let icon = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(ServerDrivenPaymentMethodFixtures.lightAndDarkJSON()).icon

        // Then a dark background uses the dark image, and a light one the light image
        XCTAssertEqual(icon.image(forDarkBackground: true).sources.first?.url, ServerDrivenPaymentMethodFixtures.iconURL("demo_pay_dark", scale: 2))
        XCTAssertEqual(icon.image(forDarkBackground: false), icon.light)

        // Given an icon with only a light image, both backgrounds use it
        let lightOnly = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod().icon
        XCTAssertEqual(lightOnly.image(forDarkBackground: true), lightOnly.light)
        XCTAssertEqual(lightOnly.image(forDarkBackground: false), lightOnly.light)
    }

    func testIcon_templateRenderingTints() throws {
        // Given a template icon
        let paymentMethodType = PaymentSheet.PaymentMethodType.serverDriven(
            try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(ServerDrivenPaymentMethodFixtures.lightAndDarkJSON(rendering: "template"))
        )

        // When it's shown in an image view
        let imageView = PaymentMethodTypeImageView(paymentMethodType: paymentMethodType, contrastMatchingColor: .black, currency: nil, iconStyle: .filled)

        // Then it's tinted to the foreground color
        XCTAssertTrue(paymentMethodType.iconRequiresTinting)
        XCTAssertEqual(imageView.image?.renderingMode, .alwaysTemplate)
        XCTAssertEqual(imageView.tintColor, .black)
    }

    func testMakeImage_decodesPickedSourceAtItsScale() throws {
        // Given an icon with 2x and 3x sources
        let paymentMethod = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod()
        let downloadManager = makeDownloadManager()
        var requestedURLs: [URL] = []
        for scale in [2, 3] {
            let url = ServerDrivenPaymentMethodFixtures.iconURL("demo_pay", scale: scale)
            stub(condition: { $0.url == url }) { request in
                requestedURLs.append(request.url!)
                return HTTPStubsResponse(data: ServerDrivenPaymentMethodFixtures.iconData(scale: scale), statusCode: 200, headers: nil)
            }
        }

        for scale in [2, 3] {
            // When it's downloaded for a screen at that scale
            let downloaded = expectation(description: "Downloaded at \(scale)x")
            var image: UIImage?
            _ = paymentMethod.makeImage(forDarkBackground: false, iconStyle: .filled, updateHandler: {
                image = $0
                downloaded.fulfill()
            }, downloadManager: downloadManager, screenScale: CGFloat(scale))
            wait(for: [downloaded], timeout: 5)

            // Then it fetches that source as is, and decodes it at the source's scale, so it fills the 30x20pt box
            XCTAssertEqual(requestedURLs.last, ServerDrivenPaymentMethodFixtures.iconURL("demo_pay", scale: scale))
            XCTAssertEqual(image?.scale, CGFloat(scale))
            XCTAssertEqual(image?.size, CGSize(width: 30, height: 20))
        }
    }

    func testMakeImage_vendsBlankPlaceholderAndLogsUntilCached() throws {
        // Given an icon that isn't cached
        let paymentMethod = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(ServerDrivenPaymentMethodFixtures.json(type: "paypal"))
        let downloadManager = makeDownloadManager()
        let analyticsClient = STPAnalyticsClient()
        let url = ServerDrivenPaymentMethodFixtures.iconURL("paypal", scale: 3)
        stub(condition: { $0.url == url }) { _ in
            HTTPStubsResponse(data: ServerDrivenPaymentMethodFixtures.iconData(scale: 3), statusCode: 200, headers: nil)
        }

        // When its image is vended to the merchant, without an update handler
        let vended = paymentMethod.makeImage(forDarkBackground: false, iconStyle: .filled, updateHandler: nil, downloadManager: downloadManager, analyticsClient: analyticsClient, screenScale: 3)

        // Then it's a clear image the size of the icon box, not the SDK's PayPal icon or a 1x1 placeholder
        XCTAssertTrue(vended === ServerDrivenPaymentMethod.blankIcon)
        XCTAssertEqual(vended.size, CGSize(width: 30, height: 20))
        XCTAssertTrue(isClear(vended))
        // ...and vending it is logged with the type
        XCTAssertEqual(analyticsClient._testLogHistory.map { $0["event"] as? String }, ["mc_server_driven_icon_placeholder_vended"])
        XCTAssertEqual(analyticsClient._testLogHistory.last?["payment_method_type"] as? String, "paypal")

        // When the icon is then downloaded, and vended again
        let downloaded = expectation(description: "Downloaded")
        _ = paymentMethod.makeImage(forDarkBackground: false, iconStyle: .filled, updateHandler: { _ in downloaded.fulfill() }, downloadManager: downloadManager, analyticsClient: analyticsClient, screenScale: 3)
        wait(for: [downloaded], timeout: 5)
        let cached = paymentMethod.makeImage(forDarkBackground: false, iconStyle: .filled, updateHandler: nil, downloadManager: downloadManager, analyticsClient: analyticsClient, screenScale: 3)

        // Then the merchant gets the icon, and nothing more is logged
        XCTAssertFalse(cached === ServerDrivenPaymentMethod.blankIcon)
        XCTAssertEqual(cached.scale, 3)
        XCTAssertEqual(analyticsClient._testLogHistory.count, 1)
    }

    func testMakeImage_rowFallsBackToBundledIconWhileLoadingAndOnFailure() throws {
        // Given icon downloads that fail
        let downloadManager = makeDownloadManager()
        let analyticsClient = STPAnalyticsClient()
        stub(condition: { $0.url?.host == "b.stripecdn.com" }) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 404, headers: nil)
        }
        func rowImage(_ json: [String: Any]) throws -> UIImage {
            let paymentMethod = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(json)
            return paymentMethod.makeImage(forDarkBackground: false, iconStyle: .filled, updateHandler: { _ in
                XCTFail("A failed download doesn't update the row")
            }, downloadManager: downloadManager, analyticsClient: analyticsClient, screenScale: 3)
        }

        // Then a row for a type the SDK has an icon for shows that icon
        let payPal = try rowImage(ServerDrivenPaymentMethodFixtures.json(type: "paypal"))
        let bundledPayPal = try XCTUnwrap(STPPaymentMethodType.payPal.makeImage(forDarkBackground: false, iconStyle: .filled))
        XCTAssertEqual(payPal.pngData(), bundledPayPal.pngData())
        XCTAssertFalse(payPal === ServerDrivenPaymentMethod.blankIcon)
        // ...a type the SDK doesn't know shows the blank icon
        XCTAssertTrue(try rowImage(ServerDrivenPaymentMethodFixtures.json()) === ServerDrivenPaymentMethod.blankIcon)
        // ...and so does a type whose bundled icon is tinted differently, since the row tints by the server's rendering
        XCTAssertTrue(try rowImage(ServerDrivenPaymentMethodFixtures.lightAndDarkJSON(type: "paypal", rendering: "template")) === ServerDrivenPaymentMethod.blankIcon)

        // ...and rows don't log the placeholder event, which is only for the merchant's image
        let failed = expectation(description: "Downloads failed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { failed.fulfill() }
        wait(for: [failed], timeout: 2)
        XCTAssertTrue(analyticsClient._testLogHistory.isEmpty)
    }

    func testPrefetchIcons_downloadsPickedLightAndDarkSources() throws {
        // Given an icon with light and dark images at 2x and 3x, and a CDN that records what's requested
        let paymentMethod = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(ServerDrivenPaymentMethodFixtures.lightAndDarkJSON())
        let downloadManager = makeDownloadManager()
        let lock = NSLock()
        var requestedURLs: Set<URL> = []
        let requested = expectation(description: "Requested light and dark")
        requested.expectedFulfillmentCount = 2
        stub(condition: { $0.url?.host == "b.stripecdn.com" }) { request in
            lock.withLock { _ = requestedURLs.insert(request.url!) }
            requested.fulfill()
            return HTTPStubsResponse(data: ServerDrivenPaymentMethodFixtures.iconData(scale: 3), statusCode: 200, headers: nil)
        }

        // When its icons are prefetched on a 3x screen
        paymentMethod.prefetchIcons(downloadManager: downloadManager, screenScale: 3)
        wait(for: [requested], timeout: 5)

        // Then the 3x light and dark sources are fetched as is, without a proxy
        XCTAssertEqual(lock.withLock { requestedURLs }, [
            ServerDrivenPaymentMethodFixtures.iconURL("demo_pay", scale: 3),
            ServerDrivenPaymentMethodFixtures.iconURL("demo_pay_dark", scale: 3),
        ])
    }

    /// Returns whether every pixel of `image` is fully transparent.
    private func isClear(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        let width = cgImage.width, height = cgImage.height
        var pixels = [UInt8](repeating: 0xFF, count: width * height * 4)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.clear(CGRect(x: 0, y: 0, width: width, height: height))
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn && stride(from: 3, to: pixels.count, by: 4).allSatisfy { pixels[$0] == 0 }
    }

    /// Returns a `DownloadManager` with its own caches, whose requests `HTTPStubs` handles.
    private func makeDownloadManager() -> DownloadManager {
        let urlSessionConfig = APIStubbedTestCase.stubbedURLSessionConfig()
        urlSessionConfig.urlCache = URLCache(memoryCapacity: 5_000_000, diskCapacity: 0)
        addTeardownBlock { HTTPStubs.removeAllStubs() }
        return DownloadManager(urlSessionConfiguration: urlSessionConfig, analyticsClient: STPAnalyticsClient(), isTesting: true)
    }

    func testPaymentMethodType() throws {
        // Given a server-driven payment method type
        let paymentMethodType = PaymentSheet.PaymentMethodType.serverDriven(try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod())

        // Then it's identified by the server's type, which analytics and paymentMethodOrder use
        XCTAssertEqual(paymentMethodType.identifier, "demo_pay")
        XCTAssertEqual(paymentMethodType.displayName, "Demo Pay")
        XCTAssertFalse(paymentMethodType.iconRequiresTinting)
        XCTAssertFalse(paymentMethodType.supportsSaveForFutureUseCheckbox())
        // ...and equality only depends on the type
        let relabeled = PaymentSheet.PaymentMethodType.serverDriven(try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(
            ServerDrivenPaymentMethodFixtures.json { $0[jsonDict: "display"]?["label"] = "Other" }
        ))
        XCTAssertEqual(paymentMethodType, relabeled)
        XCTAssertEqual(paymentMethodType.hashValue, relabeled.hashValue)
        XCTAssertNotEqual(paymentMethodType, .serverDriven(try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(ServerDrivenPaymentMethodFixtures.json(type: "other_pay"))))
        XCTAssertNotEqual(paymentMethodType, .stripe(.unknown))
    }

    func testIntentConfirmParams_confirmsAsUnknownType() throws {
        // Given a described PayPal entry
        let paymentMethod = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(ServerDrivenPaymentMethodFixtures.json(type: "paypal"))

        // When it's confirmed with a PaymentIntent
        let confirmParams = IntentConfirmParams(type: .serverDriven(paymentMethod))
        let paymentIntentParams = PaymentSheet.makePaymentIntentParams(
            confirmPaymentMethodType: .new(
                params: confirmParams.paymentMethodParams,
                paymentOptions: confirmParams.confirmPaymentMethodOptions,
                saveForFutureUseCheckboxState: confirmParams.saveForFutureUseCheckboxState
            ),
            paymentIntent: STPFixtures.paymentIntent(paymentMethodTypes: ["card", "paypal"]),
            configuration: PaymentSheet.Configuration._testValue_MostPermissive()
        )
        let encoded = STPFormEncoder.dictionary(forObject: paymentIntentParams)

        // Then it sends the entry's type as payment_method_data[type]
        XCTAssertEqual(confirmParams.paymentMethodParams.rawTypeString, "paypal")
        XCTAssertEqual(encoded[jsonDict: "payment_method_data"]?["type"] as? String, "paypal")
        // ...without mandate data or setup_future_usage, unlike native PayPal
        XCTAssertNil(encoded["mandate_data"])
        XCTAssertNil(encoded["setup_future_usage"])
        XCTAssertNil(encoded[jsonDict: "payment_method_options"]?["setup_future_usage"])
    }

    func testIntentConfirmParams_labelsAndAnalytics() throws {
        // Given confirm params for a server-driven payment method
        let confirmParams = IntentConfirmParams(type: .serverDriven(try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod()))

        // Then FlowController and Embedded show the server's label, without asserting on the `.unknown` params
        XCTAssertEqual(confirmParams.paymentSheetLabel, "Demo Pay")
        XCTAssertEqual(confirmParams.expandedPaymentSheetLabel(brand: .link), "Demo Pay")
        XCTAssertNil(confirmParams.paymentSheetSublabel)
        // ...and analytics report its type as selected_lpm
        let paymentOption = PaymentSheet.PaymentOption.new(confirmParams: confirmParams)
        XCTAssertEqual(paymentOption.paymentMethodTypeAnalyticsValue, "demo_pay")
        STPAnalyticsClient.sharedClient._testLogHistory = []
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .mcOptionSelectCustomNewPM, paymentMethodTypeAnalyticsValue: paymentOption.paymentMethodTypeAnalyticsValue)
        XCTAssertEqual(STPAnalyticsClient.sharedClient._testLogHistory.last?["selected_lpm"] as? String, "demo_pay")
    }

    func testForm_selectsRowDirectly() throws {
        // Given a server-driven payment method, which has no form elements
        let paymentMethodType = PaymentSheet.PaymentMethodType.serverDriven(try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod())
        func makeForm(configuration: PaymentSheet.Configuration) -> PaymentMethodElement {
            return PaymentSheetFormFactory(
                intent: ._testValue(),
                elementsSession: ._testCardValue(),
                configuration: .paymentElement(configuration),
                paymentMethod: paymentMethodType
            ).make()
        }

        // Then by default its form collects nothing, so the row is selected without showing a form
        XCTAssertFalse(makeForm(configuration: PaymentSheet.Configuration()).collectsUserInput)

        // ...and it collects billing details the merchant asks for
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        XCTAssertTrue(makeForm(configuration: configuration).collectsUserInput)
    }
}
