//
//  ECEViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//

@_spi(STP) @testable import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import WebKit
import XCTest

#if !canImport(CompositorServices)
@available(iOS 16.0, *)
class ECEViewControllerSnapshotTests: STPSnapshotTestCase {

    var sut: ECEViewController!
    var mockAPIClient: STPAPIClient!
    var mockDelegate: MockExpressCheckoutWebviewDelegate!
    var navigationController: UINavigationController!

    override func setUp() {
        super.setUp()

        mockAPIClient = STPAPIClient(publishableKey: "pk_test_123")
        mockDelegate = MockExpressCheckoutWebviewDelegate()
        sut = ECEViewController(apiClient: mockAPIClient,
                                shopId: "shop_id_123",
                                customerSessionClientSecret: "cuss_12345")
        sut.expressCheckoutWebviewDelegate = mockDelegate

        navigationController = UINavigationController(rootViewController: sut)
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        mockDelegate = nil
        navigationController = nil
        super.tearDown()
    }

    func testECEViewController_Default() {
        // Given
        mockDelegate.amountToReturn = 2500

        // When
        sut.loadViewIfNeeded()
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 428, height: 926)

        // Add to window for proper rendering
        let window = UIWindow(frame: navigationController.view.frame)
        window.addSubview(navigationController.view)
        window.makeKeyAndVisible()

        // Then
        STPSnapshotVerifyView(navigationController.view)
    }

    func testECEViewController_DarkMode() {
        // Given
        mockDelegate.amountToReturn = 2500

        // When
        sut.loadViewIfNeeded()
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 428, height: 926)
        navigationController.overrideUserInterfaceStyle = .dark

        // Add to window for proper rendering
        let window = UIWindow(frame: navigationController.view.frame)
        window.addSubview(navigationController.view)
        window.makeKeyAndVisible()

        // Then
        STPSnapshotVerifyView(navigationController.view)
    }

    func testECEViewController_LargeContentSize() {
        // Given
        mockDelegate.amountToReturn = 2500

        // When
        sut.loadViewIfNeeded()
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 428, height: 926)

        // Apply large content size
        let window = UIWindow(frame: navigationController.view.frame)
        window.addSubview(navigationController.view)
        window.makeKeyAndVisible()

        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = .light
        }

        if #available(iOS 17.0, *) {
            navigationController.traitOverrides.preferredContentSizeCategory = .extraExtraLarge
        }

        // Then
        STPSnapshotVerifyView(navigationController.view)
    }

    func testECEViewController_CompactWidth() {
        // Given
        mockDelegate.amountToReturn = 2500

        // When
        sut.loadViewIfNeeded()
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 320, height: 568) // iPhone SE size

        // Add to window for proper rendering
        let window = UIWindow(frame: navigationController.view.frame)
        window.addSubview(navigationController.view)
        window.makeKeyAndVisible()

        // Then
        STPSnapshotVerifyView(navigationController.view)
    }

    func testECEViewController_WithPopup() {
        // Given
        mockDelegate.amountToReturn = 2500
        sut.loadViewIfNeeded()
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 428, height: 926)

        // Add to window for proper rendering
        let window = UIWindow(frame: navigationController.view.frame)
        window.addSubview(navigationController.view)
        window.makeKeyAndVisible()

        // When - Simulate popup creation
        let configuration = WKWebViewConfiguration()
        let navigationAction = MockWKNavigationAction()
        _ = sut.webView(
            WKWebView(frame: .zero, configuration: WKWebViewConfiguration()),
            createWebViewWith: configuration,
            for: navigationAction,
            windowFeatures: WKWindowFeatures()
        )

        // Force layout update
        navigationController.view.setNeedsLayout()
        navigationController.view.layoutIfNeeded()

        // Then
        STPSnapshotVerifyView(navigationController.view)
    }

    func testECEViewController_LoadingState() {
        // Given
        mockDelegate.amountToReturn = 2500

        // When
        sut.loadViewIfNeeded()
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 428, height: 926)

        // Add to window for proper rendering
        let window = UIWindow(frame: navigationController.view.frame)
        window.addSubview(navigationController.view)
        window.makeKeyAndVisible()

        // The loading spinner should be visible initially (once the WebView is 1x1)

        // Then
        STPSnapshotVerifyView(navigationController.view)
    }
}
#endif
