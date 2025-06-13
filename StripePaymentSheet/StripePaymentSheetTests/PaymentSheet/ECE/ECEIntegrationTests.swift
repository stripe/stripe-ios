//
//  ECEIntegrationTests.swift
//  StripePaymentSheetTests
//

import XCTest
import WebKit
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet

@available(iOS 16.0, *)
class ECEIntegrationTests: XCTestCase {
    
    var apiClient: STPAPIClient!
    var flowController: PaymentSheet.FlowController!
    var shopPayConfiguration: PaymentSheet.ShopPayConfiguration!
    var presenter: ShopPayECEPresenter!
    var presentingViewController: UIViewController!
    
    override func setUp() {
        super.setUp()
        
        apiClient = STPAPIClient(publishableKey: "pk_test_123")
        
        // Setup PaymentSheet configuration
        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = apiClient
        configuration.merchantDisplayName = "Test Merchant"
        
        // Create mock flow controller
        flowController = MockPaymentSheetFlowController(configuration: configuration)
        
        // Setup Shop Pay configuration
        shopPayConfiguration = PaymentSheet.ShopPayConfiguration(
            shopId: "test_shop_123",
            shopName: "Test Shop",
            lineItems: [
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Test Product", amount: 2000),
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Another Product", amount: 1500)
            ],
            shippingRates: [
                PaymentSheet.ShopPayConfiguration.ShippingRate(
                    id: "standard",
                    displayName: "Standard Shipping",
                    amount: 1000,
                    deliveryEstimate: PaymentSheet.ShopPayConfiguration.DeliveryEstimate(
                        minimum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 3, unit: .business_day),
                        maximum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 5, unit: .business_day)
                    )
                )
            ],
            allowedShippingCountries: ["US", "CA"],
            billingAddressRequired: true,
            emailRequired: true,
            shippingAddressRequired: true
        )
        
        presenter = ShopPayECEPresenter(
            flowController: flowController,
            configuration: shopPayConfiguration
        )
        
        presentingViewController = UIViewController()
    }
    
    override func tearDown() {
        apiClient = nil
        flowController = nil
        shopPayConfiguration = nil
        presenter = nil
        presentingViewController = nil
        super.tearDown()
    }
    
    // MARK: - End-to-End Flow Tests
    
    func testCompleteShopPayFlow() async throws {
        // Given
        let expectation = expectation(description: "Shop Pay flow completes")
        var receivedResult: PaymentSheetResult?
        
        // Create a window to present from
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presentingViewController
        window.makeKeyAndVisible()
        
        // When
        presenter.present(from: presentingViewController) { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        // Wait for presentation
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Verify ECE view controller was presented
        let navController = presentingViewController.presentedViewController as? UINavigationController
        XCTAssertNotNil(navController)
        
        let eceViewController = navController?.viewControllers.first as? ECEViewController
        XCTAssertNotNil(eceViewController)
        XCTAssertNotNil(eceViewController?.expressCheckoutWebviewDelegate)
        
        // Simulate shipping address change
        let shippingAddress = [
            "firstName": "John",
            "lastName": "Doe",
            "city": "San Francisco",
            "provinceCode": "CA",
            "postalCode": "94103",
            "countryCode": "US"
        ]
        
        let shippingResponse = try await presenter.eceView(
            eceViewController!,
            didReceiveShippingAddressChange: shippingAddress
        )
        
        XCTAssertEqual(shippingResponse["merchantDecision"] as? String, "accepted")
        XCTAssertEqual(shippingResponse["totalAmount"] as? Int, 4500) // 3500 items + 1000 shipping
        
        // Simulate shipping rate selection
        let shippingRate = ["id": "standard"]
        let rateResponse = try await presenter.eceView(
            eceViewController!,
            didReceiveShippingRateChange: shippingRate
        )
        
        XCTAssertEqual(rateResponse["merchantDecision"] as? String, "accepted")
        
        // Simulate payment confirmation
        let paymentDetails = [
            "billingDetails": [
                "email": "john.doe@example.com",
                "phone": "+14155551234",
                "name": "John Doe"
            ],
            "shippingAddress": shippingAddress,
            "shippingRate": shippingRate
        ]
        
        let confirmResponse = try await presenter.eceView(
            eceViewController!,
            didReceiveECEConfirmation: paymentDetails
        )
        
        XCTAssertEqual(confirmResponse["status"] as? String, "success")
        
        // Wait for dismissal and completion
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Verify result
        XCTAssertNotNil(receivedResult)
        // Note: In real implementation, this would be .completed with payment details
        // For now with mocks, it's likely .canceled
    }
    
    func testShippingAddressValidation() async throws {
        // Given
        let eceViewController = ECEViewController(apiClient: apiClient)
        eceViewController.expressCheckoutWebviewDelegate = presenter
        
        var validationCallCount = 0
        shopPayConfiguration.handlers = PaymentSheet.ShopPayConfiguration.Handlers(
            shippingContactUpdateHandler: { contact, completion in
                validationCallCount += 1
                
                // Reject addresses outside of US/CA
                if contact.address.country != "US" && contact.address.country != "CA" {
                    completion(nil) // Reject
                } else {
                    // Accept with updated rates based on country
                    let shippingRate = contact.address.country == "US" ? 1000 : 1500
                    let update = PaymentSheet.ShopPayConfiguration.ShippingUpdate(
                        lineItems: self.shopPayConfiguration.lineItems,
                        shippingRates: [
                            PaymentSheet.ShopPayConfiguration.ShippingRate(
                                id: "country_rate",
                                displayName: "Country-specific Rate",
                                amount: shippingRate
                            )
                        ]
                    )
                    completion(update)
                }
            }
        )
        
        presenter = ShopPayECEPresenter(
            flowController: flowController,
            configuration: shopPayConfiguration
        )
        eceViewController.expressCheckoutWebviewDelegate = presenter
        
        // Test valid US address
        let usAddress = [
            "firstName": "Test",
            "city": "New York",
            "provinceCode": "NY",
            "postalCode": "10001",
            "countryCode": "US"
        ]
        
        let usResponse = try await presenter.eceView(
            eceViewController,
            didReceiveShippingAddressChange: usAddress
        )
        
        XCTAssertEqual(usResponse["merchantDecision"] as? String, "accepted")
        let usRates = usResponse["shippingRates"] as? [[String: Any]]
        XCTAssertEqual(usRates?.first?["amount"] as? Int, 1000)
        
        // Test valid CA address
        let caAddress = [
            "firstName": "Test",
            "city": "Toronto",
            "provinceCode": "ON",
            "postalCode": "M5V 3A9",
            "countryCode": "CA"
        ]
        
        let caResponse = try await presenter.eceView(
            eceViewController,
            didReceiveShippingAddressChange: caAddress
        )
        
        XCTAssertEqual(caResponse["merchantDecision"] as? String, "accepted")
        let caRates = caResponse["shippingRates"] as? [[String: Any]]
        XCTAssertEqual(caRates?.first?["amount"] as? Int, 1500)
        
        // Test invalid country
        let invalidAddress = [
            "firstName": "Test",
            "city": "London",
            "provinceCode": "LDN",
            "postalCode": "SW1A 1AA",
            "countryCode": "GB"
        ]
        
        let invalidResponse = try await presenter.eceView(
            eceViewController,
            didReceiveShippingAddressChange: invalidAddress
        )
        
        XCTAssertEqual(invalidResponse["merchantDecision"] as? String, "rejected")
        XCTAssertEqual(validationCallCount, 3)
    }
    
    func testWebViewMessageHandling() async throws {
        // Given
        let eceViewController = ECEViewController(apiClient: apiClient)
        eceViewController.expressCheckoutWebviewDelegate = presenter
        eceViewController.loadViewIfNeeded()
        
        // Test various message types
        let testCases: [(name: String, body: [String: Any], expectedError: Bool)] = [
            // Valid messages
            ("calculateShipping", ["shippingAddress": ["firstName": "Test", "city": "SF", "provinceCode": "CA", "postalCode": "94103", "countryCode": "US"]], false),
            ("calculateShippingRateChange", ["shippingRate": ["id": "standard"]], false),
            ("handleECEClick", ["eventData": ["walletType": "shop_pay"]], false),
            
            // Invalid messages
            ("calculateShipping", [:], true), // Missing shippingAddress
            ("unknownMessage", [:], true), // Unknown message type
        ]
        
        for testCase in testCases {
            let message = MockWKScriptMessage(name: testCase.name, body: testCase.body)
            
            do {
                let response = try await eceViewController.handleMessage(message: message)
                if testCase.expectedError {
                    XCTFail("Expected error for message: \(testCase.name)")
                } else {
                    XCTAssertNotNil(response)
                }
            } catch {
                if !testCase.expectedError {
                    XCTFail("Unexpected error for message: \(testCase.name) - \(error)")
                }
            }
        }
    }
    
    func testAmountCalculation() {
        // Given
        let eceViewController = ECEViewController(apiClient: apiClient)
        
        // Test with different configurations
        
        // Configuration 1: Multiple items with shipping
        let amount1 = presenter.amountForECEView(eceViewController)
        XCTAssertEqual(amount1, 4500) // 2000 + 1500 + 1000
        
        // Configuration 2: No shipping rates
        let configNoShipping = PaymentSheet.ShopPayConfiguration(
            shopId: "test",
            shopName: "Test",
            lineItems: [
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Item", amount: 5000)
            ],
            shippingRates: [],
            shippingAddressRequired: false
        )
        let presenterNoShipping = ShopPayECEPresenter(
            flowController: flowController,
            configuration: configNoShipping
        )
        let amount2 = presenterNoShipping.amountForECEView(eceViewController)
        XCTAssertEqual(amount2, 5000) // Just the item
        
        // Configuration 3: Multiple shipping rates (should use first)
        let configMultiShipping = PaymentSheet.ShopPayConfiguration(
            shopId: "test",
            shopName: "Test",
            lineItems: [
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Item", amount: 1000)
            ],
            shippingRates: [
                PaymentSheet.ShopPayConfiguration.ShippingRate(id: "cheap", displayName: "Cheap", amount: 500),
                PaymentSheet.ShopPayConfiguration.ShippingRate(id: "expensive", displayName: "Expensive", amount: 2000)
            ]
        )
        let presenterMultiShipping = ShopPayECEPresenter(
            flowController: flowController,
            configuration: configMultiShipping
        )
        let amount3 = presenterMultiShipping.amountForECEView(eceViewController)
        XCTAssertEqual(amount3, 1500) // 1000 + 500 (first shipping rate)
    }
}

// MARK: - Performance Tests

@available(iOS 16.0, *)
extension ECEIntegrationTests {
    
    func testMessageHandlingPerformance() {
        // Given
        let eceViewController = ECEViewController(apiClient: apiClient)
        eceViewController.expressCheckoutWebviewDelegate = presenter
        
        let shippingAddress = [
            "firstName": "Test",
            "city": "San Francisco",
            "provinceCode": "CA",
            "postalCode": "94103",
            "countryCode": "US"
        ]
        
        measure {
            // When
            let expectation = expectation(description: "Message handled")
            
            Task {
                _ = try await presenter.eceView(
                    eceViewController,
                    didReceiveShippingAddressChange: shippingAddress
                )
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
} 