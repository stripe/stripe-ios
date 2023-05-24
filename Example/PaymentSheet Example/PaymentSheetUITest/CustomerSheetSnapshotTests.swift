//
//  CustomerSheetSnapshotTests.swift
//  StripePaymentSheet
//

import iOSSnapshotTestCase
import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import UIKit

@_spi(STP)@testable import StripeCore
@_spi(STP) @testable import StripePayments
@_spi(STP) @_spi(ExperimentalPaymentSheetDecouplingAPI) @_spi(PrivateBetaCustomerSheet) @testable import StripePaymentSheet
@_spi(STP) @_spi(ExperimentalPaymentSheetDecouplingAPI) @_spi(PrivateBetaCustomerSheet) @testable import StripePaymentsUI
@_spi(STP)@testable import StripeUICore

// For backend example
class StubCustomerAdapter: CustomerAdapter {
    var paymentMethods: [StripePayments.STPPaymentMethod] = []

    func fetchPaymentMethods() async throws -> [StripePayments.STPPaymentMethod] {
        return paymentMethods
    }

    func attachPaymentMethod(_ paymentMethodId: String) async throws {

    }

    func detachPaymentMethod(paymentMethodId: String) async throws {

    }

    func setSelectedPaymentOption(paymentOption: CustomerPaymentOption?) async throws {

    }

    func fetchSelectedPaymentOption() async throws -> CustomerPaymentOption? {
        return nil
    }

    func setupIntentClientSecretForCustomerAttach() async throws -> String {
        return "seti_123"
    }

    var canCreateSetupIntents: Bool = true
}

class CustomerSheetSnapshotTests: FBSnapshotTestCase {

    private let backendCheckoutUrl = URL(
        string: "https://stripe-mobile-payment-sheet-test-playground-v6.glitch.me/checkout"
    )!

    private var cs: CustomerSheet!

    private var window: UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 1026))
        window.isHidden = false
        return window
    }

    private var configuration = CustomerSheet.Configuration()

    override func setUp() {
        super.setUp()

        configuration = CustomerSheet.Configuration()

        LinkAccountService.defaultCookieStore = LinkInMemoryCookieStore()  // use in-memory cookie store
//        self.recordMode = true
    }

    public override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        configuration = CustomerSheet.Configuration()
    }

    private func stubbedAPIClient() -> STPAPIClient {
        return APIStubbedTestCase.stubbedAPIClient()
    }

    func testNoSavedPMs() {
        prepareCS(applePayEnabled: false)
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    func testNoSavedPMsDarkMode() {
        prepareCS(applePayEnabled: false)
        presentCS(darkMode: true)
        verify(cs.bottomSheetViewController.view!)
    }

    func testNoSavedPMsCustomAppearance() {
        prepareCS(appearance: .snapshotTestTheme, applePayEnabled: false)
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    func testOnlyApplePay() {
        prepareCS(applePayEnabled: true)
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    func testOnlyApplePayDarkMode() {
        prepareCS(applePayEnabled: true)
        presentCS(darkMode: true)
        verify(cs.bottomSheetViewController.view!)
    }

    func testOnlyApplePayCustomAppearance() {
        prepareCS(appearance: .snapshotTestTheme, applePayEnabled: true)
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    func stubbedPaymentMethod() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123card",
            "type": "card",
            "card": [
                "last4": "4242",
                "brand": "visa",
            ],
        ])!
    }

    func testOneSavedCardPM() {
        let customerAdapter = StubCustomerAdapter()
        customerAdapter.paymentMethods = [stubbedPaymentMethod()]
        prepareCS(customerAdapter: customerAdapter, applePayEnabled: true)
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    func testOneSavedCardPMDarkMode() {
        let customerAdapter = StubCustomerAdapter()
        customerAdapter.paymentMethods = [stubbedPaymentMethod()]
        prepareCS(customerAdapter: customerAdapter, applePayEnabled: true)
        presentCS(darkMode: true)
        verify(cs.bottomSheetViewController.view!)
    }

    func testOneSavedCardPMCustomApperance() {
        let customerAdapter = StubCustomerAdapter()
        customerAdapter.paymentMethods = [stubbedPaymentMethod()]
        prepareCS(appearance: .snapshotTestTheme, customerAdapter: customerAdapter, applePayEnabled: true)
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    func testManySavedPMs() {
        let customerAdapter = StubCustomerAdapter()
        customerAdapter.paymentMethods = Array(repeating: stubbedPaymentMethod(), count: 20)
        prepareCS(customerAdapter: customerAdapter, applePayEnabled: true)
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    private func prepareCS(
        appearance: PaymentSheet.Appearance = .default,
        customerAdapter: CustomerAdapter = StubCustomerAdapter(),
        applePayEnabled: Bool = true
    ) {
        var config = self.configuration
        config.appearance = appearance
        config.apiClient = stubbedAPIClient()
        config.applePayEnabled = applePayEnabled
        StripeAPI.defaultPublishableKey = "pk_test_123456789"

        self.cs = CustomerSheet(configuration: config, customer: customerAdapter)
    }

    private func presentCS(darkMode: Bool, preferredContentSizeCategory: UIContentSizeCategory = .large) {
        let vc = UIViewController()
        let navController = UINavigationController(rootViewController: vc)
        let testWindow = self.window
        if darkMode {
            testWindow.overrideUserInterfaceStyle = .dark
        }
        testWindow.rootViewController = navController

        cs.present(from: vc) { _ in }

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
                        (self.cs.bottomSheetViewController.contentStack.first as? LoadingViewController)
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

        cs.bottomSheetViewController.presentationController!.overrideTraitCollection = UITraitCollection(
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
