//
//  PaymentSheetSnapshotTests.swift
//  PaymentSheetUITest
//
//  Created by Nick Porter on 2/25/22.
//  Copyright © 2022 stripe-ios. All rights reserved.
//

import iOSSnapshotTestCase
import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import UIKit

@_spi(STP)@testable import StripeCore
@_spi(STP)@testable import StripePaymentSheet
@_spi(STP)@testable import StripeUICore

class PaymentSheetSnapshotTests: FBSnapshotTestCase {

    private let backendCheckoutUrl = URL(
        string: "https://stripe-mobile-payment-sheet-test-playground-v6.glitch.me/checkout"
    )!

    private var paymentSheet: PaymentSheet!

    private var window: UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 1026))
        window.isHidden = false
        return window
    }

    private var configuration = PaymentSheet.Configuration()

    // Change this to true to hit the real glitch backend. This may be required
    // to capture data for new use cases
    var runAgainstLiveService: Bool = false
    override func setUp() {
        super.setUp()

        configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.applePay = .init(
            merchantId: "com.foo.example",
            merchantCountryCode: "US"
        )
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "mockReturnUrl"

        LinkAccountService.defaultCookieStore = LinkInMemoryCookieStore()  // use in-memory cookie store
//                self.recordMode = true
//                self.runAgainstLiveService = true
        if !self.runAgainstLiveService {
            APIStubbedTestCase.stubAllOutgoingRequests()
        }
    }

    public override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        configuration = PaymentSheet.Configuration()
    }

    private func stubbedAPIClient() -> STPAPIClient {
        return APIStubbedTestCase.stubbedAPIClient()
    }

    func testPaymentSheet() {
        stubNewCustomerResponse()

        preparePaymentSheet()
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetDarkMode() {
        stubNewCustomerResponse()

        preparePaymentSheet()
        presentPaymentSheet(darkMode: true)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetAppearance() {
        stubNewCustomerResponse()

        preparePaymentSheet(appearance: .snapshotTestTheme)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetPrimaryButtonAppearance() {
        stubNewCustomerResponse()

        preparePaymentSheet(appearance: .snapshotPrimaryButtonTestTheme)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetDynamicType() {
        stubNewCustomerResponse()

        preparePaymentSheet()
        presentPaymentSheet(darkMode: false, preferredContentSizeCategory: .extraExtraLarge)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetNilShadows() {
        stubNewCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.shadow = .disabled
        appearance.borderWidth = 0.0
        preparePaymentSheet(appearance: appearance)
        presentPaymentSheet(darkMode: false, preferredContentSizeCategory: .extraExtraLarge)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetShadow() {
        stubNewCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.shadow = PaymentSheet.Appearance.Shadow(
            color: .systemRed,
            opacity: 0.5,
            offset: CGSize(width: 0, height: 2),
            radius: 6
        )
        preparePaymentSheet(appearance: appearance)
        presentPaymentSheet(darkMode: false, preferredContentSizeCategory: .extraExtraLarge)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetShadowRoundsCorners() {
        stubNewCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.shadow = PaymentSheet.Appearance.Shadow(
            color: .systemBlue,
            opacity: 1.0,
            offset: CGSize(width: 6, height: 6),
            radius: 0
        )
        preparePaymentSheet(appearance: appearance)
        presentPaymentSheet(darkMode: false, preferredContentSizeCategory: .extraExtraLarge)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetFont() {
        stubNewCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.font.sizeScaleFactor = 1.15
        appearance.font.base = UIFont(name: "AvenirNext-Regular", size: UIFont.labelFontSize)!

        preparePaymentSheet(appearance: appearance)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetColors() {
        stubNewCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.colors.primary = .red
        appearance.colors.background = .lightGray
        appearance.colors.componentBackground = .black
        appearance.colors.componentBorder = .yellow
        appearance.colors.componentDivider = .green
        appearance.colors.text = .blue
        appearance.colors.textSecondary = .purple
        appearance.colors.componentText = .cyan
        appearance.colors.componentPlaceholderText = .white
        appearance.colors.icon = .orange
        appearance.colors.danger = .cyan

        preparePaymentSheet(appearance: appearance)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetPrimaryButton() {
        stubNewCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.primaryButton.backgroundColor = .red
        appearance.primaryButton.textColor = .blue
        appearance.primaryButton.cornerRadius = 0.0
        appearance.primaryButton.borderColor = .cyan
        appearance.primaryButton.borderWidth = 2.0
        appearance.primaryButton.font = UIFont(name: "AvenirNext-Regular", size: UIFont.labelFontSize)!
        appearance.primaryButton.shadow = PaymentSheet.Appearance.Shadow(
            color: .yellow,
            opacity: 0.5,
            offset: CGSize(width: 0, height: 2),
            radius: 6
        )

        preparePaymentSheet(appearance: appearance)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCornerRadius() {
        stubNewCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.cornerRadius = 0.0

        preparePaymentSheet(appearance: appearance)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetBorderWidth() {
        stubNewCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.borderWidth = 2.0

        preparePaymentSheet(appearance: appearance)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustom() {
        stubReturningCustomerResponse()

        preparePaymentSheet(customer: "snapshot")
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustomDarkMode() {
        stubReturningCustomerResponse()

        preparePaymentSheet(customer: "snapshot")
        presentPaymentSheet(darkMode: true)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustomAppearance() {
        stubReturningCustomerResponse()

        preparePaymentSheet(
            customer: "snapshot",
            appearance: .snapshotTestTheme
        )
        presentPaymentSheet(darkMode: true)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustomDynamicType() {
        stubReturningCustomerResponse()

        preparePaymentSheet(customer: "snapshot")
        presentPaymentSheet(darkMode: false, preferredContentSizeCategory: .extraExtraLarge)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustomNilShadows() {
        stubReturningCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.shadow = .disabled
        appearance.borderWidth = 0.0
        preparePaymentSheet(
            customer: "snapshot",
            appearance: appearance
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustomShadow() {
        stubReturningCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.shadow = PaymentSheet.Appearance.Shadow(
            color: .systemRed,
            opacity: 0.5,
            offset: CGSize(width: 0, height: 2),
            radius: 6
        )
        preparePaymentSheet(
            customer: "snapshot",
            appearance: appearance
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustomFont() {
        stubReturningCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.font.sizeScaleFactor = 1.15
        appearance.font.base = UIFont(name: "AvenirNext-Regular", size: UIFont.labelFontSize)!

        preparePaymentSheet(
            customer: "snapshot",
            appearance: appearance,
            applePayEnabled: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustomColors() {
        stubReturningCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.colors.primary = .red
        appearance.colors.background = .lightGray
        appearance.colors.componentBackground = .black
        appearance.colors.componentBorder = .yellow
        appearance.colors.componentDivider = .green
        appearance.colors.text = .blue
        appearance.colors.textSecondary = .purple
        appearance.colors.componentText = .cyan
        appearance.colors.componentPlaceholderText = .white
        appearance.colors.icon = .orange
        appearance.colors.danger = .cyan

        preparePaymentSheet(
            customer: "snapshot",
            appearance: appearance,
            applePayEnabled: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustomPrimaryButton() {
        stubReturningCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.primaryButton.backgroundColor = .red
        appearance.primaryButton.textColor = .blue
        appearance.primaryButton.cornerRadius = 0.0
        appearance.primaryButton.borderColor = .cyan
        appearance.primaryButton.borderWidth = 2.0
        appearance.primaryButton.font = UIFont(name: "AvenirNext-Regular", size: UIFont.labelFontSize)!
        appearance.primaryButton.shadow = PaymentSheet.Appearance.Shadow(
            color: .yellow,
            opacity: 0.5,
            offset: CGSize(width: 0, height: 2),
            radius: 6
        )

        preparePaymentSheet(
            customer: "snapshot",
            appearance: appearance,
            applePayEnabled: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustomPrimaryButtonLabel() {
        stubNewCustomerResponse()

        configuration.primaryButtonLabel = "Donate"

        preparePaymentSheet()
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustomApplePayCta() {
        stubNewCustomerResponse()

        configuration.applePay = .init(
            merchantId: "com.foo.example",
            merchantCountryCode: "US",
            buttonType: .donate
        )

        preparePaymentSheet(applePayEnabled: true)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustomPrimaryButtonAndApplePayCta() {
        stubNewCustomerResponse()

        configuration.primaryButtonLabel = "Donate"
        configuration.applePay = .init(
            merchantId: "com.foo.example",
            merchantCountryCode: "US",
            buttonType: .donate
        )

        preparePaymentSheet(applePayEnabled: true)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustomCornerRadius() {
        stubReturningCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.cornerRadius = 0.0

        preparePaymentSheet(
            customer: "snapshot",
            appearance: appearance,
            applePayEnabled: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetCustomBorderWidth() {
        stubReturningCustomerResponse()

        var appearance = PaymentSheet.Appearance()
        appearance.borderWidth = 2.0

        preparePaymentSheet(
            customer: "snapshot",
            appearance: appearance,
            applePayEnabled: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetWithLinkDarkMode() {
        stubSessions(fileMock: .elementsSessionsPaymentMethod_link_200)
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            customer: "guest",
            automaticPaymentMethods: false,
            useLink: true
        )
        presentPaymentSheet(darkMode: true)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetWithLinkAppearance() {
        stubSessions(fileMock: .elementsSessionsPaymentMethod_link_200)
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            customer: "guest",
            appearance: .snapshotTestTheme,
            automaticPaymentMethods: false,
            useLink: true
        )
        presentPaymentSheet(darkMode: true)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetWithLink() {
        stubSessions(fileMock: .elementsSessionsPaymentMethod_link_200)
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            customer: "guest",
            automaticPaymentMethods: false,
            useLink: true
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetWithLinkHiddenBorders() {
        stubSessions(fileMock: .elementsSessionsPaymentMethod_link_200)
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        var appearance = PaymentSheet.Appearance.default
        appearance.colors.componentBackground = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.00)
        appearance.borderWidth = 0.0
        preparePaymentSheet(
            customer: "guest",
            appearance: appearance,
            automaticPaymentMethods: false,
            useLink: true
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    // MARK: Deferred intent tests

    func testPaymentSheet_deferredIntent() {
        stubNewCustomerResponse()

        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD", setupFutureUsage: .offSession),
                                                            confirmHandler: confirmHandler(_:_:_:))

        preparePaymentSheet(intentConfig: intentConfig)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheetWithLink_deferredIntent() {
        stubSessions(fileMock: .elementsSessionsPaymentMethod_link_200)
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD", setupFutureUsage: .onSession),
                                                            confirmHandler: confirmHandler(_:_:_:))

        preparePaymentSheet(
            automaticPaymentMethods: false,
            intentConfig: intentConfig
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    // MARK: LPMS

    func testPaymentSheet_LPM_Affirm_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"affirm\"",
                        "<currency>": "\"usd\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            override_payment_methods_types: ["affirm"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_AfterpayClearpay_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"afterpay_clearpay\"",
                        "<currency>": "\"usd\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            override_payment_methods_types: ["afterpay_clearpay"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_klarna_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"klarna\"",
                        "<currency>": "\"usd\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            override_payment_methods_types: ["klarna"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_cashapp_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"cashapp\"",
                        "<currency>": "\"usd\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            override_payment_methods_types: ["cashapp"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_iDeal_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"ideal\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["ideal"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_bancontact_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"bancontact\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["bancontact"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_sofort_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"sofort\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["sofort"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_sepaDebit_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"sepa_debit\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["sepa_debit"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_eps_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"eps\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["eps"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_giropay_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"giropay\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["giropay"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_p24_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"p24\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(stubRequestCallback: nil, fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["p24"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_aubecs_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"au_becs_debit\"",
                        "<currency>": "\"aud\"",
                    ]
                )
            }
        )
        stubPaymentMethods(stubRequestCallback: nil, fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            currency: "aud",
            override_payment_methods_types: ["au_becs_debit"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_paypal_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"paypal\"",
                        "<currency>": "\"GBP\"",
                    ]
                )
            }
        )
        stubPaymentMethods(stubRequestCallback: nil, fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            currency: "gbp",
            override_payment_methods_types: ["paypal"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_upi_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"upi\"",
                        "<currency>": "\"inr\"",
                    ]
                )
            }
        )
        stubPaymentMethods(stubRequestCallback: nil, fileMock: .saved_payment_methods_200)
        stubCustomers()

        preparePaymentSheet(
            currency: "inr",
            override_payment_methods_types: ["upi"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)

    }

    private func updatePaymentMethodDetail(data: Data, variables: [String: String]) -> Data {
        var template = String(data: data, encoding: .utf8)!
        for (templateKey, templateValue) in variables {
            let translated = template.replacingOccurrences(of: templateKey, with: templateValue)
            template = translated
        }
        return template.data(using: .utf8)!
    }

    private func stubPaymentMethods(
        stubRequestCallback: ((URLRequest) -> Bool?)? = nil,
        fileMock: FileMock
    ) {
        guard !runAgainstLiveService else {
            return
        }
        stub { urlRequest in
            if let shouldStub = stubRequestCallback?(urlRequest) {
                return shouldStub
            }
            return urlRequest.url?.absoluteString.contains("/v1/payment_methods") ?? false
        } response: { _ in
            let mockResponseData = try! fileMock.data()
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }
    }

    private func stubCustomers() {
        guard !runAgainstLiveService else {
            return
        }
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/customers") ?? false
        } response: { _ in
            let mockResponseData = try! FileMock.customers_200.data()
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }
    }

    private func stubSessions(fileMock: FileMock, responseCallback: ((Data) -> Data)? = nil) {
        guard !runAgainstLiveService else {
            return
        }
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/elements/sessions") ?? false
        } response: { _ in
            let mockResponseData = try! fileMock.data()
            let data = responseCallback?(mockResponseData) ?? mockResponseData
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }
    }

    private func preparePaymentSheet(
        customer: String = "new",
        currency: String = "usd",
        appearance: PaymentSheet.Appearance = .default,
        override_payment_methods_types: [String]? = nil,
        automaticPaymentMethods: Bool = true,
        useLink: Bool = false,
        applePayEnabled: Bool = true,
        intentConfig: PaymentSheet.IntentConfiguration? = nil
    ) {
        if runAgainstLiveService {
            prepareLiveModePaymentSheet(
                customer: customer,
                currency: currency,
                appearance: appearance,
                override_payment_methods_types: override_payment_methods_types,
                automaticPaymentMethods: automaticPaymentMethods,
                useLink: useLink,
                applePayEnabled: applePayEnabled
            )
        } else {
            prepareMockPaymentSheet(appearance: appearance,
                                    customer: customer,
                                    applePayEnabled: applePayEnabled,
                                    intentConfig: intentConfig)
        }
    }

    private func prepareLiveModePaymentSheet(
        customer: String,
        currency: String,
        appearance: PaymentSheet.Appearance,
        override_payment_methods_types: [String]?,
        automaticPaymentMethods: Bool,
        useLink: Bool,
        applePayEnabled: Bool
    ) {
        let requestExpectation = XCTestExpectation(description: "request expectation")
        let session = URLSession.shared
        let url = backendCheckoutUrl

        var body =
            [
                "customer": customer,
                "currency": currency,
                "mode": "payment",
                "set_shipping_address": "false",
                "automatic_payment_methods": automaticPaymentMethods,
                "use_link": useLink,
            ] as [String: Any]

        if let override_payment_methods_types = override_payment_methods_types {
            body["override_payment_methods_types"] = override_payment_methods_types
        }

        let json = try! JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        let task = session.dataTask(with: urlRequest) { data, _, error in
            guard
                error == nil,
                let data = data,
                let json = try? JSONDecoder().decode([String: String].self, from: data),
                let customerId = json["customerId"],
                let customerEphemeralKeySecret = json["customerEphemeralKeySecret"],
                let paymentIntentClientSecret = json["intentClientSecret"],
                let publishableKey = json["publishableKey"]
            else {
                XCTFail("Failed to parse response")
                return
            }

            StripeAPI.defaultPublishableKey = publishableKey

            var config = self.configuration
            if customer != "guest" {
                config.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
            }
            config.appearance = appearance

            if !applePayEnabled {
                config.applePay = nil
            }
            self.paymentSheet = PaymentSheet(
                paymentIntentClientSecret: paymentIntentClientSecret,
                configuration: config
            )

            requestExpectation.fulfill()

        }

        task.resume()
        wait(for: [requestExpectation], timeout: 12.0)
    }

    private func prepareMockPaymentSheet(appearance: PaymentSheet.Appearance,
                                         customer: String,
                                         applePayEnabled: Bool = true,
                                         intentConfig: PaymentSheet.IntentConfiguration? = nil) {
        var config = self.configuration
        if customer != "guest" {
            config.customer = .init(id: "nobody", ephemeralKeySecret: "test")
        }
        config.appearance = appearance
        config.apiClient = stubbedAPIClient()
        if !applePayEnabled {
            config.applePay = nil
        }
        StripeAPI.defaultPublishableKey = "pk_test_123456789"

        var mode: PaymentSheet.InitializationMode = .paymentIntentClientSecret("pi_111111_secret_000000")
        if let intentConfig = intentConfig {
            mode = .deferredIntent(intentConfig)
        }

        self.paymentSheet = PaymentSheet(mode: mode, configuration: config)
    }

    private func presentPaymentSheet(darkMode: Bool, preferredContentSizeCategory: UIContentSizeCategory = .large) {
        let vc = UIViewController()
        let navController = UINavigationController(rootViewController: vc)
        let testWindow = self.window
        if darkMode {
            testWindow.overrideUserInterfaceStyle = .dark
        }
        testWindow.rootViewController = navController
        // Wait a turn of the runloop for the RVC to attach to the window, then present PaymentSheet
        DispatchQueue.main.async {
            self.paymentSheet.present(from: vc) { result in
                if case let .failed(error) = result {
                    XCTFail("Presentation failed: \(error)")
                }
            }
        }

        // Payment sheet usually takes anywhere between 50ms-200ms (but once in a while 2-3 seconds).
        // to present with the expected content. When the sheet is presented, it initially shows a loading screen,
        // and when it is done loading, the loading screen is replaced with the expected content.
        // Therefore, the following code polls every 50 milliseconds to check if the LoadingViewController
        // has been removed.  If the LoadingViewController is not there (or we reach the maximum number of times to poll),
        // we assume the content has been loaded and continue.
        let presentingExpectation = XCTestExpectation(description: "Presenting payment sheet")
        DispatchQueue.global(qos: .background).async {
            var isLoading = true
            var count = 0
            while isLoading && count < 10 {
                count += 1
                DispatchQueue.main.sync {
                    guard
                        (self.paymentSheet.bottomSheetViewController.contentStack.first as? LoadingViewController)
                            != nil
                    else {
                        isLoading = false
                        presentingExpectation.fulfill()
                        return
                    }
                }
                if isLoading {
                    usleep(50000)  // 50ms
                }
            }
        }
        wait(for: [presentingExpectation], timeout: 10.0)

        paymentSheet.bottomSheetViewController.presentationController!.overrideTraitCollection = UITraitCollection(
            preferredContentSizeCategory: preferredContentSizeCategory
        )
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        STPSnapshotVerifyView(
            view,
            identifier: identifier,
            suffixes: FBSnapshotTestCaseDefaultSuffixes(),
            file: file,
            line: line
        )
    }

    private func stubNewCustomerResponse() {
        stubSessions(fileMock: .elementsSessionsPaymentMethod_savedPM_200)
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
    }

    private func stubReturningCustomerResponse() {
        stubSessions(fileMock: .elementsSessionsPaymentMethod_savedPM_200)
        stubPaymentMethods(
            stubRequestCallback: { urlRequest in
                return urlRequest.url?.absoluteString.contains("/v1/payment_methods") ?? false
                    && urlRequest.url?.absoluteString.contains("type=card") ?? false
            },
            fileMock: .saved_payment_methods_withCard_200
        )
        stubPaymentMethods(
            stubRequestCallback: { urlRequest in
                return urlRequest.url?.absoluteString.contains("/v1/payment_methods") ?? false
                    && urlRequest.url?.absoluteString.contains("type=us_bank_account") ?? false
            },
            fileMock: .saved_payment_methods_200
        )
        stubPaymentMethods(
            stubRequestCallback: { urlRequest in
                return urlRequest.url?.absoluteString.contains("/v1/payment_methods") ?? false
                    && urlRequest.url?.absoluteString.contains("type=sepa_debit") ?? false
            },
            fileMock: .saved_payment_methods_200
        )
        stubCustomers()
    }

    func confirmHandler(_ paymentMethod: STPPaymentMethod,
                        _ shouldSavePaymentMethod: Bool,
                        _ intentCreationCallback: (Result<String, Error>) -> Void) {
        // no-op
    }

}

fileprivate extension PaymentSheet.Appearance {
    static var snapshotTestTheme: PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance()

        // Customize the font
        var font = PaymentSheet.Appearance.Font()
        font.sizeScaleFactor = 0.85
        font.base = UIFont(name: "AvenirNext-Regular", size: 12)!

        appearance.cornerRadius = 0.0
        appearance.borderWidth = 2.0
        appearance.shadow = PaymentSheet.Appearance.Shadow(
            color: .orange,
            opacity: 0.5,
            offset: CGSize(width: 0, height: 2),
            radius: 4
        )

        // Customize the colors
        var colors = PaymentSheet.Appearance.Colors()
        colors.primary = .systemOrange
        colors.background = .cyan
        colors.componentBackground = .yellow
        colors.componentBorder = .systemRed
        colors.componentDivider = .black
        colors.text = .red
        colors.textSecondary = .orange
        colors.componentText = .red
        colors.componentPlaceholderText = .systemBlue
        colors.icon = .green
        colors.danger = .purple

        appearance.font = font
        appearance.colors = colors

        return appearance
    }

    static var snapshotPrimaryButtonTestTheme: PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance.snapshotTestTheme

        var button = PaymentSheet.Appearance.PrimaryButton()
        button.backgroundColor = .purple
        button.textColor = .red
        button.borderColor = .blue
        button.cornerRadius = 15
        button.borderWidth = 3
        button.font = UIFont(name: "AmericanTypewriter", size: 16)
        button.shadow = PaymentSheet.Appearance.Shadow(
            color: .blue,
            opacity: 0.5,
            offset: CGSize(width: 0, height: 2),
            radius: 4
        )

        appearance.primaryButton = button

        return appearance
    }
}

public class ClassForBundle {}
@_spi(STP) public enum FileMock: String, MockData {
    public typealias ResponseType = StripeFile
    public var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case elementsSessionsPaymentMethod_200 = "MockFiles/elements_sessions_paymentMethod_200"
    case elementsSessionsPaymentMethod_savedPM_200 = "MockFiles/elements_sessions_paymentMethod_savedPM_200"
    case elementsSessionsPaymentMethod_link_200 = "MockFiles/elements_sessions_paymentMethod_link_200"

    case customers_200 = "MockFiles/customers_200"

    case saved_payment_methods_200 = "MockFiles/saved_payment_methods_200"
    case saved_payment_methods_withCard_200 = "MockFiles/saved_payment_methods_withCard_200"
}
