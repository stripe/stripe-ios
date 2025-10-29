//
//  ECEIntegrationTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
import StripePaymentsTestUtils

@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(SharedPaymentToken) import StripePaymentSheet
import WebKit
import XCTest

#if !os(visionOS)
@available(iOS 16.0, *)
@MainActor
class ECEIntegrationTests: XCTestCase {

    var apiClient: STPAPIClient!
    var mockConfiguration: PaymentSheet.Configuration!
    var shopPayConfiguration: PaymentSheet.ShopPayConfiguration!
    var presenter: ShopPayECEPresenter!
    var presentingViewController: UIViewController!
    var loadResult: PaymentSheetLoader.LoadResult!
    var analyticsHelper: PaymentSheetAnalyticsHelper!

    override func setUp() {
        super.setUp()
        apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

                // Setup PaymentSheet configuration
        mockConfiguration = PaymentSheet.Configuration()
        mockConfiguration.apiClient = apiClient
        mockConfiguration.merchantDisplayName = "Test Merchant"
        mockConfiguration.customer = .init(id: "cus_123", customerSessionClientSecret: "cuss_12345")

        // Setup Shop Pay configuration
        shopPayConfiguration = PaymentSheet.ShopPayConfiguration(
            billingAddressRequired: true,
            emailRequired: true,
            shippingAddressRequired: true,
            lineItems: [
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Test Product", amount: 2000),
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Another Product", amount: 1500),
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Shipping", amount: 1000),
            ],
            shippingRates: [
                PaymentSheet.ShopPayConfiguration.ShippingRate(
                    id: "standard",
                    amount: 1000,
                    displayName: "Standard Shipping",
                    deliveryEstimate: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.structured(
                        minimum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 3, unit: .business_day),
                        maximum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 5, unit: .business_day)
                    )
                ),
            ],
            shopId: "test_shop_123",
            allowedShippingCountries: ["US", "CA"]
        )

        // Create a real flow controller
        mockConfiguration.shopPay = shopPayConfiguration
        let intentConfig = PaymentSheet.IntentConfiguration(
            sharedPaymentTokenSessionWithMode: .payment(amount: 1000, currency: "USD"),
            sellerDetails: nil,
            preparePaymentMethodHandler: { _, _ in
                // no-op
            }
        )
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let elementsSession = STPElementsSession.emptyElementsSession
        loadResult = PaymentSheetLoader.LoadResult(
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: [],
            paymentMethodTypes: []
        )
        analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .flowController,
            configuration: mockConfiguration
        )

        let flowController = PaymentSheet.FlowController(
            configuration: mockConfiguration,
            loadResult: loadResult,
            analyticsHelper: analyticsHelper
        )

        presenter = ShopPayECEPresenter(
            flowController: flowController,
            configuration: shopPayConfiguration,
            analyticsHelper: analyticsHelper
        )

        presentingViewController = UIViewController()
    }

    override func tearDown() {
        apiClient = nil
        mockConfiguration = nil
        shopPayConfiguration = nil
        presenter = nil
        presentingViewController = nil
        loadResult = nil
        analyticsHelper = nil
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
        let eceViewController = presentingViewController?.presentedViewController as? ECEViewController
        XCTAssertNotNil(eceViewController)
        XCTAssertNotNil(eceViewController?.expressCheckoutWebviewDelegate)

        // Simulate shipping address change
        let shippingAddress: [String: Any] = [
            "name": "John Doe",
            "address": [
                "city": "San Francisco",
                "state": "CA",
                "postalCode": "94103",
                "country": "US",
            ],
        ]

        let shippingResponse = try await presenter.eceView(
            eceViewController!,
            didReceiveShippingAddressChange: shippingAddress
        )

        XCTAssertNil(shippingResponse["error"])
        XCTAssertEqual(shippingResponse["totalAmount"] as? Int, 4500) // 3500 items + 1000 shipping

        // Simulate shipping rate selection
        let shippingRate: [String: Any] = ["id": "standard", "amount": 1000, "displayName": "Standard Shipping"]
        let rateResponse = try await presenter.eceView(
            eceViewController!,
            didReceiveShippingRateChange: shippingRate
        )

        XCTAssertNil(rateResponse["error"])

        // Simulate payment confirmation
        let paymentDetails: [String: Any] = [
            "billingDetails": [
                "email": "john.doe@example.com",
                "phone": "+14155551234",
                "name": "John Doe",
            ],
            "shippingAddress": shippingAddress,
            "shippingRate": shippingRate,
            "paymentMethodOptions": [
                "shopPay": [
                    "externalSourceId": "st_zxd123456",
                ],
            ],
        ]

        let confirmResponse = try await presenter.eceView(
            eceViewController!,
            didReceiveECEConfirmation: paymentDetails
        )

        XCTAssertEqual(confirmResponse["status"] as? String, "success")

        // Wait for dismissal and completion
        await fulfillment(of: [expectation], timeout: 3.0)

        // Verify result
        XCTAssertNotNil(receivedResult)
        // Note: In real implementation, this would be .completed with payment details
        // For now with mocks, it's likely .canceled
    }

    func testShippingAddressValidation() async throws {
        // Given
        let eceViewController = ECEViewController(apiClient: apiClient,
                                                  shopId: "shop_id_123",
                                                  customerSessionClientSecret: "cuss_12345")
        eceViewController.expressCheckoutWebviewDelegate = presenter

        var validationCallCount = 0

        // Create new configuration with handlers
        let configWithHandlers = PaymentSheet.ShopPayConfiguration(
            billingAddressRequired: shopPayConfiguration.billingAddressRequired,
            emailRequired: shopPayConfiguration.emailRequired,
            shippingAddressRequired: shopPayConfiguration.shippingAddressRequired,
            lineItems: shopPayConfiguration.lineItems,
            shippingRates: shopPayConfiguration.shippingRates,
            shopId: shopPayConfiguration.shopId,
            allowedShippingCountries: shopPayConfiguration.allowedShippingCountries,
            handlers: PaymentSheet.ShopPayConfiguration.Handlers(
                shippingMethodUpdateHandler: nil,
                shippingContactUpdateHandler: { contact, completion in
                    validationCallCount += 1

                    // Reject addresses outside of US/CA
                    if contact.address.country != "US" && contact.address.country != "CA" {
                        completion(nil) // Reject
                    } else {
                        // Accept with updated rates based on country
                        let shippingRate = contact.address.country == "US" ? 1000 : 1500
                        let update = PaymentSheet.ShopPayConfiguration.ShippingContactUpdate(
                            lineItems: self.shopPayConfiguration.lineItems,
                            shippingRates: [
                                PaymentSheet.ShopPayConfiguration.ShippingRate(
                                    id: "country_rate",
                                    amount: shippingRate,
                                    displayName: "Country-specific Rate",
                                    deliveryEstimate: nil
                                ),
                            ]
                        )
                        completion(update)
                    }
                }
            )
        )

        // Update mockConfiguration with the new shopPay config
        mockConfiguration.shopPay = configWithHandlers

        // Create flow controller with updated configuration
        let flowController = PaymentSheet.FlowController(
            configuration: mockConfiguration,
            loadResult: loadResult,
            analyticsHelper: analyticsHelper
        )

        presenter = ShopPayECEPresenter(
            flowController: flowController,
            configuration: configWithHandlers,
            analyticsHelper: analyticsHelper
        )
        eceViewController.expressCheckoutWebviewDelegate = presenter

        // Test valid US address
        let usAddress: [String: Any] = [
            "name": "Test User",
            "address": [
                "city": "New York",
                "state": "NY",
                "postalCode": "10001",
                "country": "US",
            ],
        ]

        let usResponse = try await presenter.eceView(
            eceViewController,
            didReceiveShippingAddressChange: usAddress
        )

        XCTAssertNil(usResponse["error"])
        let usRates = usResponse["shippingRates"] as? [[String: Any]]
        XCTAssertEqual(usRates?.first?["amount"] as? Int, 1000)

        // Test valid CA address
        let caAddress: [String: Any] = [
            "name": "Test User",
            "address": [
                "city": "Toronto",
                "state": "ON",
                "postalCode": "M5V 3A9",
                "country": "CA",
            ],
        ]

        let caResponse = try await presenter.eceView(
            eceViewController,
            didReceiveShippingAddressChange: caAddress
        )

        XCTAssertNil(caResponse["error"])
        let caRates = caResponse["shippingRates"] as? [[String: Any]]
        XCTAssertEqual(caRates?.first?["amount"] as? Int, 1500)

        // Test invalid country
        let invalidAddress: [String: Any] = [
            "name": "Test User",
            "address": [
                "city": "London",
                "state": "LDN",
                "postalCode": "SW1A 1AA",
                "country": "GB",
            ],
        ]

        let invalidResponse = try await presenter.eceView(
            eceViewController,
            didReceiveShippingAddressChange: invalidAddress
        )

        XCTAssertNotNil(invalidResponse["error"])
        XCTAssertEqual(validationCallCount, 3)
    }

    func testWebViewMessageHandling() async throws {
        // Given
        let eceViewController = ECEViewController(apiClient: apiClient,
                                                  shopId: "shop_id_123",
                                                  customerSessionClientSecret: "cuss_12345")
        eceViewController.expressCheckoutWebviewDelegate = presenter
        eceViewController.loadViewIfNeeded()

        // Test various message types
        let testCases: [(name: String, body: [String: Any], expectedError: Bool)] = [
            // Valid messages
            ("calculateShipping", ["shippingAddress": ["name": "Test", "address": ["city": "SF", "state": "CA", "postalCode": "94103", "country": "US"]]], false),
            ("calculateShippingRateChange", ["shippingRate": ["id": "standard", "amount": 1000, "displayName": "Standard"]], false),
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
        let eceViewController = ECEViewController(apiClient: apiClient,
                                                  shopId: "shop_id_123",
                                                  customerSessionClientSecret: "cuss_12345")

        // Test with different configurations

        // Configuration 1: Multiple items with shipping
        let amount1 = presenter.amountForECEView(eceViewController)
        XCTAssertEqual(amount1, 4500) // 2000 + 1500 + 1000

        // Configuration 2: No shipping rates
        let configNoShipping = PaymentSheet.ShopPayConfiguration(
            shippingAddressRequired: false,
            lineItems: [
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Item", amount: 5000)
            ],
            shippingRates: [],
            shopId: "test"
        )
        // Create flow controller for no shipping config
        var config2 = mockConfiguration
        config2?.shopPay = configNoShipping
        let flowController2 = PaymentSheet.FlowController(
            configuration: config2!,
            loadResult: loadResult,
            analyticsHelper: analyticsHelper
        )
        let presenterNoShipping = ShopPayECEPresenter(
            flowController: flowController2,
            configuration: configNoShipping,
            analyticsHelper: analyticsHelper
        )
        let amount2 = presenterNoShipping.amountForECEView(eceViewController)
        XCTAssertEqual(amount2, 5000) // Just the item

        // Configuration 3: Multiple shipping rates (should use first)
        let configMultiShipping = PaymentSheet.ShopPayConfiguration(
            shippingAddressRequired: true,
            lineItems: [
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Item", amount: 1000),
                PaymentSheet.ShopPayConfiguration.LineItem(name: "cheap shipping", amount: 500),
            ],
            shippingRates: [
                PaymentSheet.ShopPayConfiguration.ShippingRate(id: "cheap", amount: 500, displayName: "Cheap", deliveryEstimate: nil),
                PaymentSheet.ShopPayConfiguration.ShippingRate(id: "expensive", amount: 2000, displayName: "Expensive", deliveryEstimate: nil),
            ],
            shopId: "test"
        )
        // Create flow controller for multi shipping config
        var config3 = mockConfiguration
        config3?.shopPay = configMultiShipping
        let flowController3 = PaymentSheet.FlowController(
            configuration: config3!,
            loadResult: loadResult,
            analyticsHelper: analyticsHelper
        )
        let presenterMultiShipping = ShopPayECEPresenter(
            flowController: flowController3,
            configuration: configMultiShipping,
            analyticsHelper: analyticsHelper
        )
        let amount3 = presenterMultiShipping.amountForECEView(eceViewController)
        XCTAssertEqual(amount3, 1500) // 1000 + 500 (first shipping rate)
    }

    func testShippingAddressChangeHandler_MultipleCalls() async throws {
        // Given
        let apiClient = STPAPIClient(publishableKey: "pk_test_123")
        let eceViewController = ECEViewController(apiClient: apiClient,
                                                  shopId: "shop_id_123",
                                                  customerSessionClientSecret: "cuss_12345")

        // Create flow controller with dynamic shipping configuration
        let expectation = expectation(description: "Handler should be called")
        expectation.expectedFulfillmentCount = 2 // Expect 2 calls

        var callCount = 0

        // Create new configuration with handlers
        shopPayConfiguration = PaymentSheet.ShopPayConfiguration(
            billingAddressRequired: true,
            emailRequired: true,
            shippingAddressRequired: true,
            lineItems: shopPayConfiguration.lineItems,
            shippingRates: shopPayConfiguration.shippingRates,
            shopId: shopPayConfiguration.shopId,
            allowedShippingCountries: shopPayConfiguration.allowedShippingCountries,
            handlers: PaymentSheet.ShopPayConfiguration.Handlers(
                shippingMethodUpdateHandler: nil,
                shippingContactUpdateHandler: { contact, completion in
                    callCount += 1
                    expectation.fulfill()

                    // Different response based on call count
                    if callCount == 1 {
                        // First call - return basic rates
                        let update = PaymentSheet.ShopPayConfiguration.ShippingContactUpdate(
                            lineItems: [.init(name: "Item", amount: 1000)],
                            shippingRates: [
                                PaymentSheet.ShopPayConfiguration.ShippingRate(
                                    id: "standard\(callCount)",
                                    amount: 500,
                                    displayName: "Standard",
                                    deliveryEstimate: nil
                                ),
                            ]
                        )
                        completion(update)
                    } else {
                        // Second call - return different rates based on location
                        let shippingRate = contact.address.state == "CA" ? 700 : 1000
                        let update = PaymentSheet.ShopPayConfiguration.ShippingContactUpdate(
                            lineItems: [.init(name: "Item", amount: 1000)],
                            shippingRates: [
                                PaymentSheet.ShopPayConfiguration.ShippingRate(
                                    id: "express\(callCount)",
                                    amount: shippingRate,
                                    displayName: "Express",
                                    deliveryEstimate: nil
                                ),
                            ]
                        )
                        completion(update)
                    }
                }
            )
        )

        // Update mockConfiguration with the new shopPay config
        mockConfiguration.shopPay = shopPayConfiguration

        // Create flow controller with updated configuration
        let flowController = PaymentSheet.FlowController(
            configuration: mockConfiguration,
            loadResult: loadResult,
            analyticsHelper: analyticsHelper
        )

        let presenter = ShopPayECEPresenter(
            flowController: flowController,
            configuration: shopPayConfiguration,
            analyticsHelper: analyticsHelper
        )

        eceViewController.expressCheckoutWebviewDelegate = presenter

        // When - First address change
        let firstAddress: [String: Any] = [
            "name": "John Doe",
            "address": [
                "city": "San Francisco",
                "state": "CA",
                "postalCode": "94103",
                "country": "US",
            ],
        ]

        _ = try await eceViewController.userContentController(
            WKUserContentController(),
            didReceive: MockWKScriptMessage(
                name: "calculateShipping",
                body: ["shippingAddress": firstAddress]
            ), replyHandler: { _, _ in
            }
        )

        // Second address change
        let secondAddress: [String: Any] = [
            "name": "Jane Doe",
            "address": [
                "city": "New York",
                "state": "NY",
                "postalCode": "10001",
                "country": "US",
            ],
        ]

        _ = try await eceViewController.userContentController(
            WKUserContentController(),
            didReceive: MockWKScriptMessage(
                name: "calculateShipping",
                body: ["shippingAddress": secondAddress]
            ), replyHandler: { _, _ in
            }
        )

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(callCount, 2)
    }

    // MARK: - Amount Calculation Tests

    func testAmountCalculation_WithDifferentShippingRates() async throws {
        // Given - Configuration 1: Standard with shipping
        let configWithShipping = shopPayConfiguration

        // Configuration 2: No shipping rates
        let configNoShipping = PaymentSheet.ShopPayConfiguration(
            shippingAddressRequired: false,
            lineItems: [
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Item", amount: 5000)
            ],
            shippingRates: [],
            shopId: "test"
        )

        // Create flow controller for no shipping config
        var config2 = mockConfiguration!
        config2.shopPay = configNoShipping
        let flowController2 = PaymentSheet.FlowController(
            configuration: config2,
            loadResult: PaymentSheetLoader.LoadResult(
                intent: loadResult.intent,
                elementsSession: loadResult.elementsSession,
                savedPaymentMethods: [],
                paymentMethodTypes: []
            ),
            analyticsHelper: PaymentSheetAnalyticsHelper(
                integrationShape: .flowController,
                configuration: config2
            )
        )
        let presenterNoShipping = ShopPayECEPresenter(
            flowController: flowController2,
            configuration: configNoShipping,
            analyticsHelper: analyticsHelper
        )

        // Configuration 3: Multiple shipping rates (should use first)
        let configMultiShipping = PaymentSheet.ShopPayConfiguration(
            shippingAddressRequired: true,
            lineItems: [
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Item", amount: 1000),
                PaymentSheet.ShopPayConfiguration.LineItem(name: "cheap shipping", amount: 500),
            ],
            shippingRates: [
                PaymentSheet.ShopPayConfiguration.ShippingRate(id: "cheap", amount: 500, displayName: "Cheap", deliveryEstimate: nil),
                PaymentSheet.ShopPayConfiguration.ShippingRate(id: "expensive", amount: 2000, displayName: "Expensive", deliveryEstimate: nil),
            ],
            shopId: "test"
        )

        // Create flow controller for multi shipping config
        var config3 = mockConfiguration!
        config3.shopPay = configMultiShipping
        let flowController3 = PaymentSheet.FlowController(
            configuration: config3,
            loadResult: PaymentSheetLoader.LoadResult(
                intent: loadResult.intent,
                elementsSession: loadResult.elementsSession,
                savedPaymentMethods: [],
                paymentMethodTypes: []
            ),
            analyticsHelper: PaymentSheetAnalyticsHelper(
                integrationShape: .flowController,
                configuration: config3
            )
        )
        let presenterMultiShipping = ShopPayECEPresenter(
            flowController: flowController3,
            configuration: configMultiShipping,
            analyticsHelper: analyticsHelper
        )

        let mockECEVC = ECEViewController(apiClient: apiClient,
                                          shopId: "shop_id_123",
                                          customerSessionClientSecret: "cuss_12345")

        // When/Then
        // Test 1: With standard shipping
        let amount1 = presenter.amountForECEView(mockECEVC)
        XCTAssertEqual(amount1, 4500) // 2000 + 1500 (items) + 1000 (shipping)

        // Test 2: No shipping
        let amount2 = presenterNoShipping.amountForECEView(mockECEVC)
        XCTAssertEqual(amount2, 5000) // 5000 (item only)

        // Test 3: Multiple shipping (uses first)
        let amount3 = presenterMultiShipping.amountForECEView(mockECEVC)
        XCTAssertEqual(amount3, 1500) // 1000 (item) + 500 (first shipping rate)
    }
}

// MARK: - Performance Tests

@available(iOS 16.0, *)
extension ECEIntegrationTests {

    func testMessageHandlingPerformance() {
        // Given
        let eceViewController = ECEViewController(apiClient: apiClient,
                                                  shopId: "shop_id_123",
                                                  customerSessionClientSecret: "cuss_12345")
        eceViewController.expressCheckoutWebviewDelegate = presenter

        let shippingAddress: [String: Any] = [
            "name": "Test User",
            "address": [
                "city": "San Francisco",
                "state": "CA",
                "postalCode": "94103",
                "country": "US",
            ],
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
#endif
