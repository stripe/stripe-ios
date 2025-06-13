//
//  ShopPayECEPresenterTests.swift
//  StripePaymentSheetTests
//

import XCTest
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils

@available(iOS 16.0, *)
class ShopPayECEPresenterTests: XCTestCase {
    
    var sut: ShopPayECEPresenter!
    var mockFlowController: MockPaymentSheetFlowController!
    var shopPayConfiguration: PaymentSheet.ShopPayConfiguration!
    var mockViewController: UIViewController!
    
    override func setUp() {
        super.setUp()
        
        // Setup Shop Pay configuration
        shopPayConfiguration = PaymentSheet.ShopPayConfiguration(
            shopId: "test_shop_123",
            shopName: "Test Shop",
            lineItems: [
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Item 1", amount: 1000),
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Item 2", amount: 500)
            ],
            shippingRates: [
                PaymentSheet.ShopPayConfiguration.ShippingRate(
                    id: "standard",
                    displayName: "Standard Shipping",
                    amount: 500,
                    deliveryEstimate: PaymentSheet.ShopPayConfiguration.DeliveryEstimate(
                        minimum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 5, unit: .day),
                        maximum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 7, unit: .day)
                    )
                ),
                PaymentSheet.ShopPayConfiguration.ShippingRate(
                    id: "express",
                    displayName: "Express Shipping",
                    amount: 1500,
                    deliveryEstimate: PaymentSheet.ShopPayConfiguration.DeliveryEstimate(
                        minimum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 1, unit: .day),
                        maximum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 2, unit: .day)
                    )
                )
            ],
            allowedShippingCountries: ["US", "CA"],
            billingAddressRequired: true,
            emailRequired: true,
            shippingAddressRequired: true
        )
        
        // Setup mock flow controller
        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.merchantDisplayName = "Test Merchant"
        mockFlowController = MockPaymentSheetFlowController(configuration: configuration)
        
        // Create presenter
        sut = ShopPayECEPresenter(
            flowController: mockFlowController,
            configuration: shopPayConfiguration
        )
        
        mockViewController = UIViewController()
    }
    
    override func tearDown() {
        sut = nil
        mockFlowController = nil
        shopPayConfiguration = nil
        mockViewController = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(sut)
    }
    
    // MARK: - Amount Calculation Tests
    
    func testAmountForECEView() {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockFlowController.configuration.apiClient)
        
        // When
        let amount = sut.amountForECEView(mockECEViewController)
        
        // Then
        // Item 1 (1000) + Item 2 (500) + Standard Shipping (500) = 2000
        XCTAssertEqual(amount, 2000)
    }
    
    func testAmountForECEView_NoShippingRates() {
        // Given
        shopPayConfiguration.shippingRates = []
        sut = ShopPayECEPresenter(
            flowController: mockFlowController,
            configuration: shopPayConfiguration
        )
        let mockECEViewController = ECEViewController(apiClient: mockFlowController.configuration.apiClient)
        
        // When
        let amount = sut.amountForECEView(mockECEViewController)
        
        // Then
        // Item 1 (1000) + Item 2 (500) = 1500 (no shipping)
        XCTAssertEqual(amount, 1500)
    }
    
    // MARK: - Shipping Address Change Tests
    
    func testShippingAddressChange_NoHandler_AcceptsWithDefaults() async throws {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockFlowController.configuration.apiClient)
        let shippingAddress = [
            "firstName": "John",
            "lastName": "Doe",
            "city": "San Francisco",
            "provinceCode": "CA",
            "postalCode": "94103",
            "countryCode": "US"
        ]
        
        // When
        let response = try await sut.eceView(mockECEViewController, didReceiveShippingAddressChange: shippingAddress)
        
        // Then
        XCTAssertEqual(response["merchantDecision"] as? String, "accepted")
        let lineItems = response["lineItems"] as? [[String: Any]]
        XCTAssertEqual(lineItems?.count, 2)
        XCTAssertEqual(lineItems?[0]["name"] as? String, "Item 1")
        XCTAssertEqual(lineItems?[0]["amount"] as? Int, 1000)
        
        let shippingRates = response["shippingRates"] as? [[String: Any]]
        XCTAssertEqual(shippingRates?.count, 2)
        XCTAssertEqual(shippingRates?[0]["id"] as? String, "standard")
        XCTAssertEqual(shippingRates?[0]["deliveryEstimate"] as? String, "5 Days - 7 Days")
        
        XCTAssertEqual(response["totalAmount"] as? Int, 2000)
    }
    
    func testShippingAddressChange_WithHandler_CallsHandler() async throws {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockFlowController.configuration.apiClient)
        let expectation = expectation(description: "Shipping contact handler called")
        
        var handlerCalled = false
        var receivedContact: PaymentSheet.ShopPayConfiguration.ShippingContactSelected?
        
        shopPayConfiguration.handlers = PaymentSheet.ShopPayConfiguration.Handlers(
            shippingContactUpdateHandler: { contact, completion in
                handlerCalled = true
                receivedContact = contact
                expectation.fulfill()
                
                // Return updated values
                let update = PaymentSheet.ShopPayConfiguration.ShippingUpdate(
                    lineItems: [
                        PaymentSheet.ShopPayConfiguration.LineItem(name: "Updated Item", amount: 2000)
                    ],
                    shippingRates: [
                        PaymentSheet.ShopPayConfiguration.ShippingRate(
                            id: "updated",
                            displayName: "Updated Shipping",
                            amount: 1000
                        )
                    ]
                )
                completion(update)
            }
        )
        
        sut = ShopPayECEPresenter(
            flowController: mockFlowController,
            configuration: shopPayConfiguration
        )
        
        let shippingAddress = [
            "firstName": "Jane",
            "city": "New York",
            "provinceCode": "NY",
            "postalCode": "10001",
            "countryCode": "US"
        ]
        
        // When
        let response = try await sut.eceView(mockECEViewController, didReceiveShippingAddressChange: shippingAddress)
        
        // Wait for handler
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertTrue(handlerCalled)
        XCTAssertEqual(receivedContact?.name, "Jane")
        XCTAssertEqual(receivedContact?.address.city, "New York")
        
        XCTAssertEqual(response["merchantDecision"] as? String, "accepted")
        let lineItems = response["lineItems"] as? [[String: Any]]
        XCTAssertEqual(lineItems?.count, 1)
        XCTAssertEqual(lineItems?[0]["name"] as? String, "Updated Item")
        XCTAssertEqual(response["totalAmount"] as? Int, 3000) // 2000 + 1000
    }
    
    func testShippingAddressChange_HandlerRejects() async throws {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockFlowController.configuration.apiClient)
        let expectation = expectation(description: "Shipping contact handler called")
        
        shopPayConfiguration.handlers = PaymentSheet.ShopPayConfiguration.Handlers(
            shippingContactUpdateHandler: { _, completion in
                expectation.fulfill()
                completion(nil) // Reject
            }
        )
        
        sut = ShopPayECEPresenter(
            flowController: mockFlowController,
            configuration: shopPayConfiguration
        )
        
        let shippingAddress = [
            "firstName": "Test",
            "city": "Invalid City",
            "provinceCode": "XX",
            "postalCode": "00000",
            "countryCode": "ZZ"
        ]
        
        // When
        let response = try await sut.eceView(mockECEViewController, didReceiveShippingAddressChange: shippingAddress)
        
        // Wait for handler
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(response["merchantDecision"] as? String, "rejected")
        XCTAssertEqual(response["error"] as? String, "Cannot ship to this address")
    }
    
    func testShippingAddressChange_MissingRequiredFields() async {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockFlowController.configuration.apiClient)
        let shippingAddress = [
            "firstName": "John"
            // Missing required fields
        ]
        
        // When/Then
        do {
            _ = try await sut.eceView(mockECEViewController, didReceiveShippingAddressChange: shippingAddress)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is ExpressCheckoutError)
        }
    }
    
    // MARK: - Shipping Rate Change Tests
    
    func testShippingRateChange_NoHandler_Accepts() async throws {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockFlowController.configuration.apiClient)
        let shippingRate = [
            "id": "express",
            "displayName": "Express Shipping",
            "amount": 1500
        ]
        
        // When
        let response = try await sut.eceView(mockECEViewController, didReceiveShippingRateChange: shippingRate)
        
        // Then
        XCTAssertEqual(response["merchantDecision"] as? String, "accepted")
        XCTAssertEqual(response["totalAmount"] as? Int, 3000) // Items (1500) + Express (1500)
    }
    
    func testShippingRateChange_InvalidRateId() async {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockFlowController.configuration.apiClient)
        let shippingRate = [
            "id": "invalid_rate_id"
        ]
        
        // When/Then
        do {
            _ = try await sut.eceView(mockECEViewController, didReceiveShippingRateChange: shippingRate)
            XCTFail("Should have thrown an error")
        } catch let error as ExpressCheckoutError {
            switch error {
            case .invalidShippingRate(let rateId):
                XCTAssertEqual(rateId, "invalid_rate_id")
            default:
                XCTFail("Unexpected error type")
            }
        }
    }
    
    // MARK: - ECE Click Tests
    
    func testECEClick_ReturnsProperConfiguration() async throws {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockFlowController.configuration.apiClient)
        let event = [
            "walletType": "shop_pay",
            "expressPaymentType": "shop_pay"
        ]
        
        // When
        let response = try await sut.eceView(mockECEViewController, didReceiveECEClick: event)
        
        // Then
        let lineItems = response["lineItems"] as? [[String: Any]]
        XCTAssertEqual(lineItems?.count, 2)
        
        XCTAssertEqual(response["billingAddressRequired"] as? Bool, true)
        XCTAssertEqual(response["emailRequired"] as? Bool, true)
        XCTAssertEqual(response["phoneNumberRequired"] as? Bool, true)
        XCTAssertEqual(response["shippingAddressRequired"] as? Bool, true)
        XCTAssertEqual(response["shopId"] as? String, "test_shop_123")
        
        let business = response["business"] as? [String: String]
        XCTAssertEqual(business?["name"], "Test Merchant")
        
        let allowedCountries = response["allowedShippingCountries"] as? [String]
        XCTAssertEqual(allowedCountries, ["US", "CA"])
        
        let shippingRates = response["shippingRates"] as? [[String: Any]]
        XCTAssertEqual(shippingRates?.count, 2)
    }
    
    // MARK: - ECE Confirmation Tests
    
    func testECEConfirmation_Success() async throws {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockFlowController.configuration.apiClient)
        let paymentDetails = [
            "billingDetails": [
                "email": "test@example.com",
                "phone": "+14155551234",
                "name": "John Doe"
            ],
            "shippingAddress": ["address1": "123 Main St"],
            "shippingRate": ["id": "standard"],
            "mode": "payment",
            "captureMethod": "automatic"
        ]
        
        // When
        let response = try await sut.eceView(mockECEViewController, didReceiveECEConfirmation: paymentDetails)
        
        // Then
        XCTAssertEqual(response["status"] as? String, "success")
        XCTAssertEqual(response["requiresAction"] as? Bool, false)
    }
    
    func testECEConfirmation_MissingBillingDetails() async {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockFlowController.configuration.apiClient)
        let paymentDetails = [
            "shippingAddress": ["address1": "123 Main St"]
            // Missing billingDetails
        ]
        
        // When/Then
        do {
            _ = try await sut.eceView(mockECEViewController, didReceiveECEConfirmation: paymentDetails)
            XCTFail("Should have thrown an error")
        } catch let error as ExpressCheckoutError {
            switch error {
            case .missingRequiredField(let field):
                XCTAssertEqual(field, "billingDetails")
            default:
                XCTFail("Unexpected error type")
            }
        }
    }
    
    // MARK: - Helper Method Tests
    
    func testDeliveryEstimateFormatting() {
        // Test same value and unit
        let estimate1 = PaymentSheet.ShopPayConfiguration.DeliveryEstimate(
            minimum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 3, unit: .day),
            maximum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 3, unit: .day)
        )
        let formatted1 = sut.test_formatDeliveryEstimate(estimate1)
        XCTAssertEqual(formatted1, "3 Days")
        
        // Test different values
        let estimate2 = PaymentSheet.ShopPayConfiguration.DeliveryEstimate(
            minimum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 1, unit: .week),
            maximum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 2, unit: .week)
        )
        let formatted2 = sut.test_formatDeliveryEstimate(estimate2)
        XCTAssertEqual(formatted2, "1 Week - 2 Weeks")
        
        // Test singular units
        let estimate3 = PaymentSheet.ShopPayConfiguration.DeliveryEstimate(
            minimum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 1, unit: .business_day),
            maximum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 1, unit: .business_day)
        )
        let formatted3 = sut.test_formatDeliveryEstimate(estimate3)
        XCTAssertEqual(formatted3, "1 Business Day")
    }
}

// MARK: - Mock Classes

@available(iOS 16.0, *)
class MockPaymentSheetFlowController: PaymentSheet.FlowController {
    let mockConfiguration: PaymentSheet.Configuration
    
    init(configuration: PaymentSheet.Configuration) {
        self.mockConfiguration = configuration
    }
    
    var paymentOption: PaymentSheet.FlowController.PaymentOptionDisplayData? {
        return nil
    }
    
    func confirm(from presentingViewController: UIViewController, completion: @escaping (PaymentSheetResult) -> Void) {
        completion(.canceled)
    }
    
    func update(with updateParams: PaymentSheet.FlowController.UpdateParams, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
    
    func presentPaymentOptions(from presentingViewController: UIViewController, completion: @escaping () -> Void) {
        completion()
    }
    
    override var configuration: PaymentSheet.Configuration {
        return mockConfiguration
    }
    
    override var intent: Intent {
        return .deferredIntent(intentConfig: PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "USD"),
            confirmHandler: { _, _, completion in
                completion(["test": "value"])
            }
        ))
    }
}

// MARK: - Test Helper Extensions

@available(iOS 16.0, *)
extension ShopPayECEPresenter {
    // Expose private methods for testing
    func test_formatDeliveryEstimate(_ estimate: PaymentSheet.ShopPayConfiguration.DeliveryEstimate) -> String {
        return formatDeliveryEstimate(estimate)
    }
} 