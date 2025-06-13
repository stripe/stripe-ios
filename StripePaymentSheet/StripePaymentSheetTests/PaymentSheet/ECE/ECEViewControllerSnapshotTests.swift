//
//  ECEViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//

import XCTest
@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import StripeCoreTestUtils

@available(iOS 16.0, *)
class ECEViewControllerSnapshotTests: STPSnapshotTestCase {
    
    var sut: ECEViewController!
    var mockAPIClient: STPAPIClient!
    var mockDelegate: MockExpressCheckoutWebviewDelegate!
    var navigationController: UINavigationController!
    
    override func setUp() {
        super.setUp()
//        recordMode = true
        
        mockAPIClient = STPAPIClient(publishableKey: "pk_test_123")
        mockDelegate = MockExpressCheckoutWebviewDelegate()
        sut = ECEViewController(apiClient: mockAPIClient)
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
        
        // Then
        verify(navigationController.view)
    }
    
    func testECEViewController_DarkMode() {
        // Given
        mockDelegate.amountToReturn = 2500
        
        // When
        sut.loadViewIfNeeded()
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 428, height: 926)
        navigationController.overrideUserInterfaceStyle = .dark
        
        // Then
        verify(navigationController.view)
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
        
        navigationController.view.subviews.forEach { subview in
            subview.adjustsFontForContentSizeCategory = true
        }
        
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = .light
        }
        
        navigationController.traitOverrides.preferredContentSizeCategory = .extraExtraLarge
        
        // Then
        verify(navigationController.view)
    }
    
    func testECEViewController_CompactWidth() {
        // Given
        mockDelegate.amountToReturn = 2500
        
        // When
        sut.loadViewIfNeeded()
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 320, height: 568) // iPhone SE size
        
        // Then
        verify(navigationController.view)
    }
    
    func testECEViewController_WithPopup() {
        // Given
        mockDelegate.amountToReturn = 2500
        sut.loadViewIfNeeded()
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 428, height: 926)
        
        // When - Simulate popup creation
        let configuration = WKWebViewConfiguration()
        let navigationAction = MockWKNavigationAction()
        _ = sut.webView(
            WKWebView(),
            createWebViewWith: configuration,
            for: navigationAction,
            windowFeatures: WKWindowFeatures()
        )
        
        // Force layout update
        navigationController.view.setNeedsLayout()
        navigationController.view.layoutIfNeeded()
        
        // Then
        verify(navigationController.view)
    }
    
    func testECEViewController_LoadingState() {
        // Given
        mockDelegate.amountToReturn = 2500
        
        // When
        sut.loadViewIfNeeded()
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 428, height: 926)
        
        // The loading spinner should be visible initially
        
        // Then
        verify(navigationController.view)
    }
} 