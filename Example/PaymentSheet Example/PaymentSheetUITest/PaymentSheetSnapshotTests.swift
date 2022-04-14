//
//  PaymentSheetSnapshotTests.swift
//  PaymentSheetUITest
//
//  Created by Nick Porter on 2/25/22.
//  Copyright © 2022 stripe-ios. All rights reserved.
//

import UIKit
import FBSnapshotTestCase
import StripeCoreTestUtils

@_spi(STP) @testable import Stripe
@_spi(STP) @testable import StripeUICore

class PaymentSheetSnapshotTests: FBSnapshotTestCase {
    
    private let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet-test-playground-v6.glitch.me/checkout")!
    
    private var paymentSheet: PaymentSheet!
    
    private var window: UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        window.isHidden = false
        return window
    }
    
    private var configuration: PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.applePay = .init(
            merchantId: "com.foo.example", merchantCountryCode: "US")
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "mockReturnUrl"
        
        return configuration
    }
    
    override func setUp() {
        super.setUp()
        LinkAccountService.defaultCookieStore = LinkInMemoryCookieStore() // use in-memory cookie store
//        self.recordMode = true
    }
    
    func testPaymentSheet() {
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation)
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetDarkMode() {
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation)
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: true)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetAppearance() {
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation, apperance: .snapshotTestTheme)
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetDynamicType() {
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation)
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: false, preferredContentSizeCategory: .extraExtraLarge)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetNilShadows() {
        var appearance = PaymentSheet.Appearance()
        appearance.shadow = nil
        appearance.borderWidth = 0.0
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation, apperance: appearance)
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: false, preferredContentSizeCategory: .extraExtraLarge)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetShadow() {
        var appearance = PaymentSheet.Appearance()
        appearance.shadow = PaymentSheet.Appearance.Shadow(color: .systemRed, opacity: 0.5, offset: CGSize(width: 0, height: 2), radius: 0.5)
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation, apperance: appearance)
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: false, preferredContentSizeCategory: .extraExtraLarge)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetCustom() {
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation, customer: "snapshot")
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetCustomDarkMode() {
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation, customer: "snapshot")
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: true)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetCustomAppearance() {
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation, customer: "snapshot", apperance: .snapshotTestTheme)
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: true)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetCustomDynamicType() {
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation, customer: "snapshot")
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: false, preferredContentSizeCategory: .extraExtraLarge)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetCustomNilShadows() {
        var appearance = PaymentSheet.Appearance()
        appearance.shadow = nil
        appearance.borderWidth = 0.0
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation, customer: "snapshot", apperance: appearance)
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetCustomShadow() {
        var appearance = PaymentSheet.Appearance()
        appearance.shadow = PaymentSheet.Appearance.Shadow(color: .systemRed, opacity: 0.5, offset: CGSize(width: 0, height: 2), radius: 0.5)
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation, customer: "snapshot", apperance: appearance)
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetWithLinkDarkMode() {
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation, automaticPaymentMethods: false, useLink: true)
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: true)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetWithLinkAppearance() {
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation,
                            apperance: .snapshotTestTheme,
                            automaticPaymentMethods: false,
                            useLink: true)
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: true)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    func testPaymentSheetWithLink() {
        let requestExpectation = XCTestExpectation(description: "request expectation")
        preparePaymentSheet(requestExpectation: requestExpectation, automaticPaymentMethods: false, useLink: true)
        wait(for: [requestExpectation], timeout: 20.0)
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    
    private func preparePaymentSheet(requestExpectation: XCTestExpectation,
                                     customer: String = "new",
                                     apperance: PaymentSheet.Appearance = .default,
                                     automaticPaymentMethods: Bool = true,
                                     useLink: Bool = false) {
        
        let session = URLSession.shared
        let url = URL(string: "https://stripe-mobile-payment-sheet-test-playground-v6.glitch.me/checkout")!
        
        let body = [
            "customer": customer,
            "currency": "usd",
            "mode": "payment",
            "set_shipping_address": "false",
            "automatic_payment_methods": automaticPaymentMethods,
            "use_link": useLink
        ] as [String: Any]
        
        let json = try! JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        let task = session.dataTask(with: urlRequest) { data, response, error in
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
            config.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
            config.appearance = apperance

            self.paymentSheet = PaymentSheet(
                paymentIntentClientSecret: paymentIntentClientSecret,
                configuration: config)

            requestExpectation.fulfill()
            
        }
        
        task.resume()
    }
    
    private func presentPaymentSheet(darkMode: Bool, preferredContentSizeCategory: UIContentSizeCategory = .large) {
        let vc = UIViewController()
        let navController = UINavigationController(rootViewController: vc)
        let testWindow = self.window
        if darkMode {
            testWindow.overrideUserInterfaceStyle = .dark
        }
        testWindow.rootViewController = navController
        
        paymentSheet.present(from: vc, completion: { _ in })
        
        _ = XCTWaiter.wait(for: [expectation(description: "Wait for n seconds")], timeout: 5.0)
        
        paymentSheet.bottomSheetViewController.presentationController!.overrideTraitCollection = UITraitCollection(preferredContentSizeCategory: preferredContentSizeCategory)
    }
    
    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        STPSnapshotVerifyView(view,
                             identifier: identifier,
                             suffixes: FBSnapshotTestCaseDefaultSuffixes(),
                             file: file,
                             line: line)
    }
    
}

private extension PaymentSheet.Appearance {
    static var snapshotTestTheme: PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance()

        // Customize the font
        var font = PaymentSheet.Appearance.Font()
        font.sizeScaleFactor = 0.85
        font.base = UIFont(name: "AvenirNext-Regular", size: 12)!
        

        appearance.cornerRadius = 0.0
        appearance.borderWidth = 2.0
        appearance.shadow = PaymentSheet.Appearance.Shadow(color: .orange,
                                                           opacity: 0.5,
                                                          offset: CGSize(width: 0, height: 2),
                                                                     radius: 4)

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
}
