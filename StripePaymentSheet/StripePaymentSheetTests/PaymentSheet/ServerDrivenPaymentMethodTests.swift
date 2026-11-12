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

/// `mobile_session.payment_methods` entries for tests.
enum ServerDrivenPaymentMethodFixtures {
    static let lightIconURL = "https://b.stripecdn.com/ocs-mobile/assets/pm/demo_pay.png"

    /// Returns a DemoPay-like entry: no form, a redirect, no mandate. `modify` changes it.
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
            "form": ["elements": [[String: Any]]()],
            "confirm": [
                "payment_method_data_type": type,
                "next_actions": [
                    [
                        "type": "redirect_to_url",
                        "presenter": "redirect",
                        "url_path": "url",
                        "browser": "from_next_action",
                        "return_url": "next_action",
                        "app_to_app": "universal_links_only",
                    ],
                ],
                "mandate_data": "none",
                "intent_retrieval": "retrieve",
                "intent_rules": [
                    "payment_intent": [
                        "after_confirm": [
                            "processing": ["outcome": "succeed"],
                            "requires_action": ["outcome": "perform_next_action"],
                        ],
                        "after_next_action": [
                            "processing": ["outcome": "succeed"],
                            "requires_action": ["outcome": "poll", "poll_seconds": 5, "on_timeout": "cancel"] as [String: Any],
                        ],
                    ],
                ],
                "return_url": "required",
                "setup": ["supported": false],
            ] as [String: Any],
            "saved_payment_methods": "unsupported",
        ]
        modify(&json)
        return json
    }

    /// Decodes `json` the way the sidecar is decoded.
    static func paymentMethod(_ json: [String: Any] = json()) throws -> MobileSession.PaymentMethod {
        let data = try JSONSerialization.data(withJSONObject: ["payment_methods": [json]])
        return try XCTUnwrap(MobileSession.decode(data).paymentMethods?.first)
    }

    static func serverDrivenPaymentMethod(_ json: [String: Any] = json()) throws -> ServerDrivenPaymentMethod {
        return try ServerDrivenPaymentMethod(paymentMethod(json))
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

        // Then it keeps the display and confirm values
        XCTAssertEqual(paymentMethod.type, "demo_pay")
        XCTAssertEqual(paymentMethod.label, "Demo Pay")
        XCTAssertEqual(paymentMethod.subtitle, "Pay with Demo Pay")
        XCTAssertEqual(paymentMethod.paymentMethodDataType, "demo_pay")
        XCTAssertEqual(paymentMethod.icon.light, .init(url: URL(string: ServerDrivenPaymentMethodFixtures.lightIconURL)!))
        XCTAssertFalse(paymentMethod.icon.isTemplate)
        // ...and reads its confirm the same way as a served payment_method_confirmations entry
        let served = try ConfirmationMetadata(wire: ServerDrivenPaymentMethodFixtures.paymentMethod().confirm, type: "demo_pay")
        XCTAssertEqual(paymentMethod.confirmation, served)
        XCTAssertEqual(Array(paymentMethod.confirmation.nextActions.keys), ["redirect_to_url"])
        XCTAssertEqual(paymentMethod.confirmation.paymentIntent.afterConfirm, .init(processing: .succeed, requiresAction: .performNextAction))
        XCTAssertEqual(paymentMethod.confirmation.paymentIntent.afterNextAction, .init(processing: .succeed, requiresAction: .poll(seconds: 5, onTimeout: .cancel)))
        XCTAssertNil(paymentMethod.confirmation.setupIntent)
        XCTAssertEqual(paymentMethod.confirmation.retrieval, .retrieve)
        XCTAssertEqual(paymentMethod.confirmation.params.returnURL, .required)
    }

    func testInit_readsAnyPresenter() throws {
        // Given a description whose next action is a polling screen, as a served entry for BLIK has
        let json = ServerDrivenPaymentMethodFixtures.json {
            $0[jsonDict: "confirm"]?["next_actions"] = [
                [
                    "type": "blik_authorize",
                    "presenter": "polling_screen",
                    "return_url": "none",
                    "app_to_app": "none",
                    "polling_screen": [
                        "seconds": 60, "interval_seconds": 3, "shows_countdown": true, "over_web_view": false,
                        "title": "Approve payment", "instructions": "Open your bank app. {time_remaining}",
                        "cancel_button": "Cancel", "failure_title": "Payment failed", "failure_instructions": "Try again",
                    ] as [String: Any],
                ] as [String: Any],
            ]
        }

        // When it's mapped
        let paymentMethod = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(json)

        // Then the engine performs it with the polling screen
        guard case .pollingScreen(let screen, let overWebView) = paymentMethod.confirmation.nextActions["blik_authorize"]?.presenter else {
            return XCTFail("Expected a polling screen, got \(String(describing: paymentMethod.confirmation.nextActions))")
        }
        XCTAssertEqual(screen.seconds, 60)
        XCTAssertFalse(overWebView)
    }

    func testInit_throwsForValuesItCantRender() throws {
        // Each entry has one value this SDK can't render, and throws that value
        let cases: [(String, (inout [String: Any]) -> Void)] = [
            ("form_element:unparsable", { $0["form"] = ["elements": [["type": "name"]]] }),
            // The confirm is read with the served entries' mapping, which names the field it can't follow
            ("confirm.next_actions[redirect_to_url].presenter", { $0[jsonDict: "confirm"]?["next_actions"] = [["type": "redirect_to_url", "presenter": "carrier_pigeon", "return_url": "next_action", "app_to_app": "none"]] }),
            ("confirm.next_actions[redirect_to_url].browser", { $0[jsonDict: "confirm"]?["next_actions"] = [["type": "redirect_to_url", "presenter": "redirect", "return_url": "next_action", "app_to_app": "none"]] }),
            ("confirm.intent_retrieval", { $0[jsonDict: "confirm"]?["intent_retrieval"] = "webhook" }),
            ("confirm.return_url", { $0[jsonDict: "confirm"]?["return_url"] = "sometimes" }),
            ("confirm.intent_rules.payment_intent.after_next_action.processing.outcome", { $0[jsonDict: "confirm"]?[jsonDict: "intent_rules"]?[jsonDict: "payment_intent"]?[jsonDict: "after_next_action"]?["processing"] = ["outcome": "show_pending"] }),
            ("confirm.intent_rules.payment_intent.after_next_action.requires_action.on_timeout", { $0[jsonDict: "confirm"]?[jsonDict: "intent_rules"]?[jsonDict: "payment_intent"]?[jsonDict: "after_next_action"]?["requires_action"] = ["outcome": "poll", "poll_seconds": 5] as [String: Any] }),
            ("confirm.intent_rules.payment_intent.after_next_action.requires_action.poll_seconds", { $0[jsonDict: "confirm"]?[jsonDict: "intent_rules"]?[jsonDict: "payment_intent"]?[jsonDict: "after_next_action"]?["requires_action"] = ["outcome": "poll", "poll_seconds": -1, "on_timeout": "cancel"] as [String: Any] }),
            // iOS still builds confirm params in code, and sends no mandate for these
            ("mandate_data:online_inferred_when_setting_up", { $0[jsonDict: "confirm"]?["mandate_data"] = "online_inferred_when_setting_up" }),
            ("mandate_data:online_inferred", { $0[jsonDict: "confirm"]?["mandate_data"] = "online_inferred" }),
            ("mandate_data:unparsable", { $0[jsonDict: "confirm"]?["mandate_data"] = "offline" }),
            ("saved_payment_methods:unparsable", { $0["saved_payment_methods"] = "supported" }),
            ("icon_rendering:unparsable", { $0[jsonDict: "display"]?[jsonDict: "icon"]?["rendering"] = "vector" }),
            ("icon:invalid_url", { $0[jsonDict: "display"]?[jsonDict: "icon"]?[jsonDict: "light"]?["url"] = "http://js.stripe.com/icon.png" }),
            ("icon:invalid_url", { $0[jsonDict: "display"]?[jsonDict: "icon"]?["dark"] = ["url": ""] }),
            ("type:empty", { $0[jsonDict: "confirm"]?["payment_method_data_type"] = "" }),
        ]
        for (expectedValue, modify) in cases {
            let paymentMethod = try ServerDrivenPaymentMethodFixtures.paymentMethod(ServerDrivenPaymentMethodFixtures.json(modify))
            XCTAssertThrowsError(try ServerDrivenPaymentMethod(paymentMethod), expectedValue) { error in
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

    func testIntentConfirmParams_confirmsWithPaymentMethodDataType() throws {
        // Given a server-driven payment method whose payment_method_data type differs from its type
        let paymentMethod = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(
            ServerDrivenPaymentMethodFixtures.json { $0[jsonDict: "confirm"]?["payment_method_data_type"] = "demo_pay_data" }
        )

        // When it's confirmed with a PaymentIntent
        let confirmParams = IntentConfirmParams(type: .serverDriven(paymentMethod))
        let paymentIntentParams = PaymentSheet.makePaymentIntentParams(
            confirmPaymentMethodType: .new(
                params: confirmParams.paymentMethodParams,
                paymentOptions: confirmParams.confirmPaymentMethodOptions,
                saveForFutureUseCheckboxState: confirmParams.saveForFutureUseCheckboxState
            ),
            paymentIntent: STPFixtures.paymentIntent(paymentMethodTypes: ["card", "demo_pay"]),
            configuration: PaymentSheet.Configuration._testValue_MostPermissive()
        )
        let encoded = STPFormEncoder.dictionary(forObject: paymentIntentParams)

        // Then it sends the entry's payment_method_data type
        XCTAssertEqual(encoded[jsonDict: "payment_method_data"]?["type"] as? String, "demo_pay_data")
        // ...without mandate data or setup_future_usage
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
