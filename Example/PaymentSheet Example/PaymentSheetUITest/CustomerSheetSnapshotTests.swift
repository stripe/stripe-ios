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
@_spi(STP) @_spi(PrivateBetaCustomerSheet) @testable import StripePaymentSheet
@_spi(STP) @_spi(PrivateBetaCustomerSheet) @testable import StripePaymentsUI
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

    override func setUp() {
        super.setUp()

        LinkAccountService.defaultCookieStore = LinkInMemoryCookieStore()  // use in-memory cookie store
//        self.recordMode = true
    }

    public override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    private func stubbedAPIClient() -> STPAPIClient {
        return APIStubbedTestCase.stubbedAPIClient()
    }

    func testNoSavedPMs() {
        prepareCS(configuration: configuration())
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    func testNoSavedPMsDarkMode() {
        prepareCS(configuration: configuration())
        presentCS(darkMode: true)
        verify(cs.bottomSheetViewController.view!)
    }

    func testNoSavedPMsCustomAppearance() {
        prepareCS(configuration: configuration(appearance: .snapshotTestTheme))
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    func testOnlyApplePay() {
        prepareCS(configuration: configuration(applePayEnabled: true))
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    func testOnlyApplePayDarkMode() {
        prepareCS(configuration: configuration(applePayEnabled: true))
        presentCS(darkMode: true)
        verify(cs.bottomSheetViewController.view!)
    }

    func testOnlyApplePayCustomAppearance() {
        prepareCS(configuration: configuration(applePayEnabled: true, appearance: .snapshotTestTheme))
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    /// first digit - name
    /// first digit - phone
    /// first digit - email
    /// first digit - address
    /// 0 == .automatic
    /// 1 == .never
    /// 2 == (always || full)
    func testBillingDetailsCollection_0000() {
        let bdcc = billingDetailsCollectionConfiguration(name: .automatic,
                                                         phone: .automatic,
                                                         email: .automatic,
                                                         address: .automatic)

        prepareCS(configuration: configuration(billingDetailsCollectionConfiguration: bdcc))
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }
    func testBillingDetailsCollection_1000() {
        let bdcc = billingDetailsCollectionConfiguration(name: .never,
                                                         phone: .automatic,
                                                         email: .automatic,
                                                         address: .automatic)

        prepareCS(configuration: configuration(billingDetailsCollectionConfiguration: bdcc))
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }
    func testBillingDetailsCollection_2000() {
        let bdcc = billingDetailsCollectionConfiguration(name: .always,
                                                         phone: .automatic,
                                                         email: .automatic,
                                                         address: .automatic)

        prepareCS(configuration: configuration(billingDetailsCollectionConfiguration: bdcc))
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }
    func testBillingDetailsCollection_0100() {
        let bdcc = billingDetailsCollectionConfiguration(name: .automatic,
                                                         phone: .never,
                                                         email: .automatic,
                                                         address: .automatic)

        prepareCS(configuration: configuration(billingDetailsCollectionConfiguration: bdcc))
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }
    func testBillingDetailsCollection_0200() {
        let bdcc = billingDetailsCollectionConfiguration(name: .automatic,
                                                         phone: .never,
                                                         email: .automatic,
                                                         address: .automatic)

        prepareCS(configuration: configuration(billingDetailsCollectionConfiguration: bdcc))
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }
    func testBillingDetailsCollection_0010() {
        let bdcc = billingDetailsCollectionConfiguration(name: .automatic,
                                                         phone: .automatic,
                                                         email: .always,
                                                         address: .automatic)

        prepareCS(configuration: configuration(billingDetailsCollectionConfiguration: bdcc))
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }
    func testBillingDetailsCollection_0020() {
        let bdcc = billingDetailsCollectionConfiguration(name: .automatic,
                                                         phone: .automatic,
                                                         email: .never,
                                                         address: .automatic)

        prepareCS(configuration: configuration(billingDetailsCollectionConfiguration: bdcc))
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }
    func testBillingDetailsCollection_0001() {
        let bdcc = billingDetailsCollectionConfiguration(name: .automatic,
                                                         phone: .automatic,
                                                         email: .automatic,
                                                         address: .never)

        prepareCS(configuration: configuration(billingDetailsCollectionConfiguration: bdcc))
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }
    func testBillingDetailsCollection_0002() {
        let bdcc = billingDetailsCollectionConfiguration(name: .automatic,
                                                         phone: .automatic,
                                                         email: .automatic,
                                                         address: .full)

        prepareCS(configuration: configuration(billingDetailsCollectionConfiguration: bdcc))
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }
    func testBillingDetailsCollection_2222() {
        let bdcc = billingDetailsCollectionConfiguration(name: .always,
                                                         phone: .always,
                                                         email: .always,
                                                         address: .full)

        prepareCS(configuration: configuration(billingDetailsCollectionConfiguration: bdcc))
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }
    func testBillingDetailsCollection_2222_withDefaults() {
        let bdcc = billingDetailsCollectionConfiguration(name: .always,
                                                         phone: .always,
                                                         email: .always,
                                                         address: .full)

        prepareCS(configuration: configuration(defaultBillingDetails: billingDetails(),
                                               billingDetailsCollectionConfiguration: bdcc))
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
        prepareCS(configuration: configuration(applePayEnabled: true), customerAdapter: customerAdapter)
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    func testOneSavedCardPMDarkMode() {
        let customerAdapter = StubCustomerAdapter()
        customerAdapter.paymentMethods = [stubbedPaymentMethod()]
        prepareCS(configuration: configuration(applePayEnabled: true), customerAdapter: customerAdapter)
        presentCS(darkMode: true)
        verify(cs.bottomSheetViewController.view!)
    }

    func testOneSavedCardPMCustomApperance() {
        let customerAdapter = StubCustomerAdapter()
        customerAdapter.paymentMethods = [stubbedPaymentMethod()]
        prepareCS(configuration: configuration(applePayEnabled: true, appearance: .snapshotTestTheme), customerAdapter: customerAdapter)
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    func testManySavedPMs() {
        let customerAdapter = StubCustomerAdapter()
        customerAdapter.paymentMethods = Array(repeating: stubbedPaymentMethod(), count: 20)
        prepareCS(configuration: configuration(applePayEnabled: true), customerAdapter: customerAdapter)
        presentCS(darkMode: false)
        verify(cs.bottomSheetViewController.view!)
    }

    private func billingDetails() -> PaymentSheet.BillingDetails {
        return .init(
            address: .init(
                city: "San Francisco",
                country: "US",
                line1: "510 Townsend St.",
                postalCode: "94102",
                state: "California"
            ),
            email: "foo@bar.com",
            name: "Jane Doe",
            phone: "+13105551234")
    }
    private func billingDetailsCollectionConfiguration(
        name: PaymentSheet.BillingDetailsCollectionConfiguration.CollectionMode = .automatic,
        phone: PaymentSheet.BillingDetailsCollectionConfiguration.CollectionMode = .automatic,
        email: PaymentSheet.BillingDetailsCollectionConfiguration.CollectionMode = .automatic,
        address: PaymentSheet.BillingDetailsCollectionConfiguration.AddressCollectionMode = .automatic,
        attachDefaultsToPaymentMethod: Bool = false) -> PaymentSheet.BillingDetailsCollectionConfiguration {
        return .init(name: name,
                     phone: phone,
                     email: email,
                     address: address,
                     attachDefaultsToPaymentMethod: attachDefaultsToPaymentMethod)
    }
    private func configuration(applePayEnabled: Bool = false,
                               defaultBillingDetails: PaymentSheet.BillingDetails = .init(),
                               billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration = .init(),
                               appearance: PaymentSheet.Appearance = .default) -> CustomerSheet.Configuration {
        var config = CustomerSheet.Configuration()
        config.applePayEnabled = applePayEnabled
        config.appearance = appearance
        config.apiClient = stubbedAPIClient()
        config.defaultBillingDetails = defaultBillingDetails
        config.billingDetailsCollectionConfiguration = billingDetailsCollectionConfiguration

        return config
    }
    private func prepareCS(
        configuration: CustomerSheet.Configuration,
        customerAdapter: CustomerAdapter = StubCustomerAdapter()
    ) {
        StripeAPI.defaultPublishableKey = "pk_test_123456789"
        self.cs = CustomerSheet(configuration: configuration, customer: customerAdapter)
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
