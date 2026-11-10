//
//  ServerDrivenPaymentMethodTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 11/10/26.
//

import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) @_spi(AppearanceAPIAdditionsPreview) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsTestUtils
@testable@_spi(InternalOnlyAPI) import StripeUICore

/// `mobile_session.payment_methods` entries for tests.
enum ServerDrivenPaymentMethodFixtures {
    static let lightIconURL = "https://js.stripe.com/test/icon-pm-demopay@3x.png"

    /// Returns a DemoPay-like entry: no form, a redirect, no mandate. `modify` changes it.
    static func json(type: String = "demo_pay", _ modify: (inout [String: Any]) -> Void = { _ in }) -> [String: Any] {
        var json: [String: Any] = [
            "type": type,
            "display": [
                "label": "Demo Pay",
                "subtitle": "Pay with Demo Pay",
                "icon": [
                    "light": ["url": lightIconURL, "scale": 3, "width": 48, "height": 48] as [String: Any],
                    "rendering": "original",
                ] as [String: Any],
            ] as [String: Any],
            "form": ["elements": [[String: Any]]()],
            "confirm": [
                "payment_method_data_type": type,
                "next_actions": ["redirect_to_url"],
                "mandate_data": "none",
                "setup_future_usage": "none",
                "processing_is_success": true,
                "post_redirect_poll_seconds": 5,
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
        XCTAssertEqual(paymentMethod.icon.light, .init(url: URL(string: ServerDrivenPaymentMethodFixtures.lightIconURL)!, scale: 3))
        XCTAssertFalse(paymentMethod.icon.isTemplate)
        XCTAssertTrue(paymentMethod.processingIsSuccess)
        XCTAssertEqual(paymentMethod.postRedirectPollSeconds, 5)
    }

    func testInit_throwsForValuesItCantRender() throws {
        // Each entry has one value this SDK can't render, and throws that value
        let cases: [(String, (inout [String: Any]) -> Void)] = [
            ("form_element:unparsable", { $0["form"] = ["elements": [["type": "name"]]] }),
            ("next_action:unparsable", { $0[jsonDict: "confirm"]?["next_actions"] = ["redirect_to_url", "confirm_on_mobile_device"] }),
            ("mandate_data:online_inferred", { $0[jsonDict: "confirm"]?["mandate_data"] = "online_inferred" }),
            ("mandate_data:unparsable", { $0[jsonDict: "confirm"]?["mandate_data"] = "offline" }),
            ("setup_future_usage:off_session", { $0[jsonDict: "confirm"]?["setup_future_usage"] = "off_session" }),
            ("setup_future_usage:on_session", { $0[jsonDict: "confirm"]?["setup_future_usage"] = "on_session" }),
            ("saved_payment_methods:unparsable", { $0["saved_payment_methods"] = "supported" }),
            ("icon_rendering:unparsable", { $0[jsonDict: "display"]?[jsonDict: "icon"]?["rendering"] = "vector" }),
            ("icon:invalid_url", { $0[jsonDict: "display"]?[jsonDict: "icon"]?[jsonDict: "light"]?["url"] = "http://js.stripe.com/icon.png" }),
            ("icon:invalid_url", { $0[jsonDict: "display"]?[jsonDict: "icon"]?["dark"] = ["url": "", "scale": 3, "width": 48, "height": 48] as [String: Any] }),
            ("icon:invalid_scale", { $0[jsonDict: "display"]?[jsonDict: "icon"]?[jsonDict: "light"]?["scale"] = 0 }),
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
        // Given an icon with every variant, each at a different scale
        func image(_ name: String, scale: Int) -> [String: Any] {
            return ["url": "https://js.stripe.com/\(name).png", "scale": scale, "width": 48, "height": 48]
        }
        let json = ServerDrivenPaymentMethodFixtures.json {
            $0[jsonDict: "display"]?["icon"] = [
                "light": image("light", scale: 1),
                "dark": image("dark", scale: 2),
                "outlined_light": image("outlined_light", scale: 3),
                "outlined_dark": image("outlined_dark", scale: 4),
                "rendering": "template",
            ] as [String: Any]
        }
        let icon = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(json).icon

        // Then each background and style picks its own variant, with the server's scale
        XCTAssertEqual(icon.image(forDarkBackground: false, iconStyle: .filled), .init(url: URL(string: "https://js.stripe.com/light.png")!, scale: 1))
        XCTAssertEqual(icon.image(forDarkBackground: true, iconStyle: .filled), .init(url: URL(string: "https://js.stripe.com/dark.png")!, scale: 2))
        XCTAssertEqual(icon.image(forDarkBackground: false, iconStyle: .outlined), .init(url: URL(string: "https://js.stripe.com/outlined_light.png")!, scale: 3))
        XCTAssertEqual(icon.image(forDarkBackground: true, iconStyle: .outlined), .init(url: URL(string: "https://js.stripe.com/outlined_dark.png")!, scale: 4))
        // ...and template rendering tints it
        XCTAssertTrue(PaymentSheet.PaymentMethodType.serverDriven(try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(json)).iconRequiresTinting)
    }

    func testIcon_outlinedDarkFallsBackToDark() throws {
        // Given an icon with a dark image but no outlined images
        let json = ServerDrivenPaymentMethodFixtures.json {
            $0[jsonDict: "display"]?[jsonDict: "icon"]?["dark"] = ["url": "https://js.stripe.com/dark.png", "scale": 3, "width": 48, "height": 48] as [String: Any]
        }
        let icon = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(json).icon

        // Then the outlined style uses the filled image for its background
        XCTAssertEqual(icon.image(forDarkBackground: true, iconStyle: .outlined), icon.dark)
        XCTAssertEqual(icon.image(forDarkBackground: false, iconStyle: .outlined), icon.light)
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
