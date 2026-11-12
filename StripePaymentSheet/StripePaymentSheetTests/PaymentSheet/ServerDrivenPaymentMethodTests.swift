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
    static let lightIconURL = "https://b.stripecdn.com/ocs-mobile/assets/pm/demo_pay.png"

    /// Returns a described DemoPay entry. `modify` changes it.
    static func json(type: String = "demo_pay", _ modify: (inout [String: Any]) -> Void = { _ in }) -> [String: Any] {
        var json: [String: Any] = [
            "type": type,
            "display": [
                "label": "Demo Pay",
                "subtitle": "Pay with Demo Pay",
                "icon": [
                    "light": ["url": lightIconURL],
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

    /// Returns an entry whose icon has every variant, at https://js.stripe.com/<variant>.png.
    static func allVariantsJSON() -> [String: Any] {
        return json {
            $0[jsonDict: "display"]?["icon"] = [
                "light": ["url": "https://js.stripe.com/light.png"],
                "dark": ["url": "https://js.stripe.com/dark.png"],
                "outlined_light": ["url": "https://js.stripe.com/outlined_light.png"],
                "outlined_dark": ["url": "https://js.stripe.com/outlined_dark.png"],
                "rendering": "template",
            ] as [String: Any]
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
        XCTAssertEqual(paymentMethod.icon.light, .init(url: URL(string: ServerDrivenPaymentMethodFixtures.lightIconURL)!))
        XCTAssertFalse(paymentMethod.icon.isTemplate)
    }

    func testInit_throwsForValuesItCantRender() throws {
        // Each entry has one value this SDK can't render, and throws that value
        let cases: [(String, (inout [String: Any]) -> Void)] = [
            ("icon_rendering:unparsable", { $0[jsonDict: "display"]?[jsonDict: "icon"]?["rendering"] = "vector" }),
            ("icon:invalid_url", { $0[jsonDict: "display"]?[jsonDict: "icon"]?[jsonDict: "light"]?["url"] = "http://js.stripe.com/icon.png" }),
            ("icon:invalid_url", { $0[jsonDict: "display"]?[jsonDict: "icon"]?["dark"] = ["url": ""] }),
            ("type:empty", { $0["type"] = "" }),
        ]
        for (expectedValue, modify) in cases {
            let entry = try ServerDrivenPaymentMethodFixtures.entry(ServerDrivenPaymentMethodFixtures.json(modify))
            XCTAssertThrowsError(try ServerDrivenPaymentMethod(type: entry.type, display: XCTUnwrap(entry.display)), expectedValue) { error in
                XCTAssertEqual(error as? ServerDrivenPaymentMethod.UnsupportedValue, .init(value: expectedValue))
            }
        }
    }

    func testIcon_fallsBackToLight() throws {
        // Given an icon with only a light image
        let icon = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod().icon

        // Then every background and style uses it
        for forDarkBackground in [false, true] {
            for iconStyle in [PaymentSheet.Appearance.IconStyle.filled, .outlined] {
                XCTAssertEqual(icon.image(forDarkBackground: forDarkBackground, iconStyle: iconStyle), icon.light)
            }
        }
    }

    func testIcon_picksVariants() throws {
        // Given an icon with every variant
        let json = ServerDrivenPaymentMethodFixtures.allVariantsJSON()
        let icon = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(json).icon

        // Then each background and style picks its own variant
        XCTAssertEqual(icon.image(forDarkBackground: false, iconStyle: .filled), .init(url: URL(string: "https://js.stripe.com/light.png")!))
        XCTAssertEqual(icon.image(forDarkBackground: true, iconStyle: .filled), .init(url: URL(string: "https://js.stripe.com/dark.png")!))
        XCTAssertEqual(icon.image(forDarkBackground: false, iconStyle: .outlined), .init(url: URL(string: "https://js.stripe.com/outlined_light.png")!))
        XCTAssertEqual(icon.image(forDarkBackground: true, iconStyle: .outlined), .init(url: URL(string: "https://js.stripe.com/outlined_dark.png")!))
        // ...and template rendering tints it
        XCTAssertTrue(PaymentSheet.PaymentMethodType.serverDriven(try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(json)).iconRequiresTinting)
    }

    func testIcon_outlinedDarkFallsBackToDark() throws {
        // Given an icon with a dark image but no outlined images
        let json = ServerDrivenPaymentMethodFixtures.json {
            $0[jsonDict: "display"]?[jsonDict: "icon"]?["dark"] = ["url": "https://js.stripe.com/dark.png"]
        }
        let icon = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(json).icon

        // Then the outlined style uses the filled image for its background
        XCTAssertEqual(icon.image(forDarkBackground: true, iconStyle: .outlined), icon.dark)
        XCTAssertEqual(icon.image(forDarkBackground: false, iconStyle: .outlined), icon.light)
    }

    func testIconDownload_usesImageProxy() throws {
        // Given an icon whose URL has a percent-encoded path and a query
        let url = try XCTUnwrap(URL(string: "https://b.stripecdn.com/ocs-mobile/assets/pm/demo%20pay.png?v=2"))
        let image = ServerDrivenPaymentMethod.Icon.Image(url: url)

        // When it's downloaded 20pt tall on a 3x screen
        let download = image.download(height: 20, dpr: 3)

        // Then it's fetched through the image proxy at that height and scale, with the source URL unchanged
        XCTAssertEqual(
            download.url.absoluteString,
            "https://img.stripecdn.com/cdn-cgi/image/format=png,height=20,dpr=3/https://b.stripecdn.com/ocs-mobile/assets/pm/demo%20pay.png?v=2"
        )
        // ...and decoded at the scale it asked for
        XCTAssertEqual(download.scale, 3)
        XCTAssertEqual(image.download(height: 12, dpr: 2).url.absoluteString, "https://img.stripecdn.com/cdn-cgi/image/format=png,height=12,dpr=2/\(url.absoluteString)")
        XCTAssertEqual(image.download(height: 12, dpr: 2).scale, 2)
    }

    func testMakeImage_decodesIconAtScreenScale() throws {
        // Given an icon, and a proxy that returns it 20pt tall at the screen's scale
        let iconURL = "https://b.stripecdn.com/ocs-mobile/assets/pm/test_decode_\(UUID().uuidString).png"
        let paymentMethod = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(ServerDrivenPaymentMethodFixtures.json {
            $0[jsonDict: "display"]?[jsonDict: "icon"]?[jsonDict: "light"]?["url"] = iconURL
        })
        let dpr = StripeImageProxy.screenDPR
        let proxyURL = StripeImageProxy.url(for: URL(string: iconURL)!, format: .png, height: ServerDrivenPaymentMethod.iconHeight, dpr: dpr)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let iconData = UIGraphicsImageRenderer(size: CGSize(width: 30 * dpr, height: 20 * dpr), format: format).pngData { _ in }
        stub(condition: { $0.url == proxyURL }) { _ in
            HTTPStubsResponse(data: iconData, statusCode: 200, headers: nil)
        }
        addTeardownBlock { HTTPStubs.removeAllStubs() }

        // When it's downloaded
        let downloaded = expectation(description: "Downloaded")
        var image: UIImage?
        _ = paymentMethod.makeImage(forDarkBackground: false, iconStyle: .filled) {
            image = $0
            downloaded.fulfill()
        }
        wait(for: [downloaded], timeout: 5)

        // Then it's decoded at the scale it asked for, so it's 20pt tall
        XCTAssertEqual(image?.scale, CGFloat(dpr))
        XCTAssertEqual(image?.size, CGSize(width: 30, height: 20))
    }

    func testPrefetchIcons_downloadsVariantsForIconStyle() throws {
        // Given an icon with every variant, and a proxy that records what's requested
        let paymentMethod = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(ServerDrivenPaymentMethodFixtures.allVariantsJSON())
        let urlSessionConfig = APIStubbedTestCase.stubbedURLSessionConfig()
        urlSessionConfig.urlCache = URLCache(memoryCapacity: 5_000_000, diskCapacity: 0)
        let downloadManager = DownloadManager(urlSessionConfiguration: urlSessionConfig, analyticsClient: STPAnalyticsClient(), isTesting: true)
        let lock = NSLock()
        var requestedURLs: Set<URL> = []
        let requested = expectation(description: "Requested both outlined variants")
        requested.expectedFulfillmentCount = 2
        let iconData = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 20)).pngData { _ in }
        stub(condition: { $0.url?.host == "img.stripecdn.com" }) { request in
            lock.withLock { _ = requestedURLs.insert(request.url!) }
            requested.fulfill()
            return HTTPStubsResponse(data: iconData, statusCode: 200, headers: nil)
        }
        addTeardownBlock { HTTPStubs.removeAllStubs() }

        // When its icons are prefetched for the outlined style
        paymentMethod.prefetchIcons(iconStyle: .outlined, downloadManager: downloadManager)
        wait(for: [requested], timeout: 5)

        // Then the outlined light and dark variants are fetched through the proxy, at the size rows draw them
        let expectedURLs = Set(["outlined_light", "outlined_dark"].map {
            StripeImageProxy.url(for: URL(string: "https://js.stripe.com/\($0).png")!, format: .png, height: ServerDrivenPaymentMethod.iconHeight, dpr: StripeImageProxy.screenDPR)
        })
        XCTAssertEqual(lock.withLock { requestedURLs }, expectedURLs)
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
