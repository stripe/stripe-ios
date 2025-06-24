//
//  ShopPayECEPresenterTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
import UIKit
import XCTest

@available(iOS 16.0, *)
@MainActor
class ShopPayECEPresenterTests: XCTestCase {

    var sut: ShopPayECEPresenter!
    var mockConfiguration: PaymentSheet.Configuration!
    var shopPayConfiguration: PaymentSheet.ShopPayConfiguration!
    var mockViewController: UIViewController!
    var mockFlowController: PaymentSheet.FlowController!

    override func setUp() {
        super.setUp()

        // Setup Shop Pay configuration
        shopPayConfiguration = PaymentSheet.ShopPayConfiguration(
            billingAddressRequired: true,
            emailRequired: true,
            shippingAddressRequired: true,
            lineItems: [
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Item 1", amount: 1000),
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Item 2", amount: 500),
            ],
            shippingRates: [
                PaymentSheet.ShopPayConfiguration.ShippingRate(
                    id: "standard",
                    amount: 500,
                    displayName: "Standard Shipping",
                    deliveryEstimate: PaymentSheet.ShopPayConfiguration.DeliveryEstimate(
                        minimum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 5, unit: .business_day),
                        maximum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 7, unit: .business_day)
                    )
                ),
                PaymentSheet.ShopPayConfiguration.ShippingRate(
                    id: "express",
                    amount: 1500,
                    displayName: "Express Shipping",
                    deliveryEstimate: PaymentSheet.ShopPayConfiguration.DeliveryEstimate(
                        minimum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 1, unit: .day),
                        maximum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 2, unit: .day)
                    )
                ),
            ],
            shopId: "test_shop_123",
            allowedShippingCountries: ["US", "CA"]
        )

        // Setup mock configuration
        mockConfiguration = PaymentSheet.Configuration()
        mockConfiguration.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        mockConfiguration.merchantDisplayName = "Test Merchant"
        mockConfiguration.shopPay = shopPayConfiguration

        // Create mock flow controller
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "USD"),
            confirmHandler: { _, _, completion in
                completion(.failure(NSError(domain: "test", code: 0)))
            }
        )
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let elementsSession = STPElementsSession.emptyElementsSession
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: [],
            paymentMethodTypes: []
        )
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .flowController,
            configuration: mockConfiguration
        )

        mockFlowController = PaymentSheet.FlowController(
            configuration: mockConfiguration,
            loadResult: loadResult,
            analyticsHelper: analyticsHelper
        )

        // Create presenter
        sut = ShopPayECEPresenter(
            flowController: mockFlowController,
            configuration: shopPayConfiguration
        )

        mockViewController = UIViewController()
    }

    override func tearDown() {
        sut = nil
        mockConfiguration = nil
        shopPayConfiguration = nil
        mockViewController = nil
        mockFlowController = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(sut)
    }

    // MARK: - Amount Calculation Tests

    func testAmountForECEView() {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockConfiguration.apiClient)

        // When
        let amount = sut.amountForECEView(mockECEViewController)

        // Then
        // Item 1 (1000) + Item 2 (500) + Standard Shipping (500) = 2000
        XCTAssertEqual(amount, 2000)
    }

    func testAmountForECEView_NoShippingRates() {
        // Given
        let noShippingConfig = PaymentSheet.ShopPayConfiguration(
            billingAddressRequired: true,
            emailRequired: true,
            shippingAddressRequired: false,
            lineItems: shopPayConfiguration.lineItems,
            shippingRates: [],
            shopId: shopPayConfiguration.shopId,
            allowedShippingCountries: shopPayConfiguration.allowedShippingCountries
        )
        sut = ShopPayECEPresenter(
            flowController: mockFlowController,
            configuration: noShippingConfig
        )
        let mockECEViewController = ECEViewController(apiClient: mockConfiguration.apiClient)

        // When
        let amount = sut.amountForECEView(mockECEViewController)

        // Then
        // Item 1 (1000) + Item 2 (500) = 1500 (no shipping)
        XCTAssertEqual(amount, 1500)
    }

    // MARK: - Shipping Address Change Tests

    func testShippingAddressChange_NoHandler_AcceptsWithDefaults() async throws {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockConfiguration.apiClient)
        let shippingAddress: [String: Any] = [
            "name": "John Doe",
            "address": [
                "city": "San Francisco",
                "state": "CA",
                "postalCode": "94103",
                "country": "US",
            ],
        ]

        // When
        let response = try await sut.eceView(mockECEViewController, didReceiveShippingAddressChange: shippingAddress)

        // Then
        XCTAssertNil(response["error"])
        let lineItems = response["lineItems"] as? [[String: Any]]
        XCTAssertEqual(lineItems?.count, 2)
        XCTAssertEqual(lineItems?[0]["name"] as? String, "Item 1")
        XCTAssertEqual(lineItems?[0]["amount"] as? Int, 1000)

        let shippingRates = response["shippingRates"] as? [[String: Any]]
        XCTAssertEqual(shippingRates?.count, 2)
        XCTAssertEqual(shippingRates?[0]["id"] as? String, "standard")

        // Check delivery estimate structure
        if let deliveryEstimate = shippingRates?[0]["deliveryEstimate"] as? [String: Any],
           let minimum = deliveryEstimate["minimum"] as? [String: Any],
           let maximum = deliveryEstimate["maximum"] as? [String: Any] {
            XCTAssertEqual(minimum["value"] as? Int, 5)
            XCTAssertEqual(minimum["unit"] as? String, "business_day")
            XCTAssertEqual(maximum["value"] as? Int, 7)
            XCTAssertEqual(maximum["unit"] as? String, "business_day")
        }

        XCTAssertEqual(response["totalAmount"] as? Int, 2000)
    }

    func testShippingAddressChange_WithHandler_CallsHandler() async throws {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockConfiguration.apiClient)
        let expectation = expectation(description: "Shipping contact handler called")

        var handlerCalled = false
        var receivedContact: PaymentSheet.ShopPayConfiguration.ShippingContactSelected?

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
                    handlerCalled = true
                    receivedContact = contact
                    expectation.fulfill()

                    // Return updated values
                    let update = PaymentSheet.ShopPayConfiguration.ShippingContactUpdate(
                        lineItems: [
                            PaymentSheet.ShopPayConfiguration.LineItem(name: "Updated Item", amount: 2000)
                        ],
                        shippingRates: [
                            PaymentSheet.ShopPayConfiguration.ShippingRate(
                                id: "updated",
                                amount: 1000,
                                displayName: "Updated Shipping",
                                deliveryEstimate: nil
                            ),
                        ]
                    )
                    completion(update)
                }
            )
        )

        sut = ShopPayECEPresenter(
            flowController: mockFlowController,
            configuration: shopPayConfiguration
        )

        let shippingAddress: [String: Any] = [
            "name": "Jane Doe",
            "address": [
                "city": "New York",
                "state": "NY",
                "postalCode": "10001",
                "country": "US",
            ],
        ]

        // When
        let response = try await sut.eceView(mockECEViewController, didReceiveShippingAddressChange: shippingAddress)

        // Wait for handler
        await fulfillment(of: [expectation], timeout: 1.0)

        // Then
        XCTAssertTrue(handlerCalled)
        XCTAssertEqual(receivedContact?.name, "Jane Doe")
        XCTAssertEqual(receivedContact?.address.city, "New York")

        XCTAssertNil(response["error"])
        let lineItems = response["lineItems"] as? [[String: Any]]
        XCTAssertEqual(lineItems?.count, 1)
        XCTAssertEqual(lineItems?[0]["name"] as? String, "Updated Item")
        XCTAssertEqual(response["totalAmount"] as? Int, 3000) // 2000 + 1000
    }

    func testShippingAddressChange_HandlerRejects() async throws {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockConfiguration.apiClient)
        let expectation = expectation(description: "Shipping contact handler called")

        // Create new configuration with handlers that reject
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
                shippingContactUpdateHandler: { _, completion in
                    expectation.fulfill()
                    completion(nil) // Reject
                }
            )
        )

        sut = ShopPayECEPresenter(
            flowController: mockFlowController,
            configuration: shopPayConfiguration
        )

        let shippingAddress: [String: Any] = [
            "name": "Test User",
            "address": [
                "city": "Invalid City",
                "state": "XX",
                "postalCode": "00000",
                "country": "ZZ",
            ],
        ]

        // When
        let response = try await sut.eceView(mockECEViewController, didReceiveShippingAddressChange: shippingAddress)

        // Wait for handler
        await fulfillment(of: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(response["error"] as? String, "Cannot ship to this address")
    }

    func testShippingAddressChange_MissingRequiredFields() async {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockConfiguration.apiClient)
        let shippingAddress = [
            "name": "John"
            // Missing address object
        ]

        // When/Then
        do {
            _ = try await sut.eceView(mockECEViewController, didReceiveShippingAddressChange: shippingAddress)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is ECEBridgeError || error is DecodingError)
        }
    }

    // MARK: - Shipping Rate Change Tests

    func testShippingRateChange_NoHandler_Accepts() async throws {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockConfiguration.apiClient)
        let shippingRate: [String: Any] = [
            "id": "express",
            "displayName": "Express Shipping",
            "amount": 1500,
        ]

        // When
        let response = try await sut.eceView(mockECEViewController, didReceiveShippingRateChange: shippingRate)

        // Then
        XCTAssertNil(response["error"])
        XCTAssertEqual(response["totalAmount"] as? Int, 3000) // Items (1500) + Express (1500)
    }

    func testShippingRateChange_WithHandler_CallsHandler() async throws {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockConfiguration.apiClient)
        let expectation = expectation(description: "Shipping method handler called")

        var handlerCalled = false

        // Create new configuration with shipping method handler
        shopPayConfiguration = PaymentSheet.ShopPayConfiguration(
            billingAddressRequired: true,
            emailRequired: true,
            shippingAddressRequired: true,
            lineItems: shopPayConfiguration.lineItems,
            shippingRates: shopPayConfiguration.shippingRates,
            shopId: shopPayConfiguration.shopId,
            allowedShippingCountries: shopPayConfiguration.allowedShippingCountries,
            handlers: PaymentSheet.ShopPayConfiguration.Handlers(
                shippingMethodUpdateHandler: { _, completion in
                    handlerCalled = true
                    expectation.fulfill()

                    // Return updated values
                    let update = PaymentSheet.ShopPayConfiguration.ShippingRateUpdate(
                        lineItems: [
                            PaymentSheet.ShopPayConfiguration.LineItem(name: "Updated Item", amount: 3000)
                        ],
                        shippingRates: [
                            PaymentSheet.ShopPayConfiguration.ShippingRate(
                                id: "super-express",
                                amount: 2000,
                                displayName: "Super Express",
                                deliveryEstimate: nil
                            ),
                        ]
                    )
                    completion(update)
                },
                shippingContactUpdateHandler: nil
            )
        )

        sut = ShopPayECEPresenter(
            flowController: mockFlowController,
            configuration: shopPayConfiguration
        )

        let shippingRate: [String: Any] = ["id": "express", "amount": 1000, "displayName": "Express Shipping"]

        // When
        let response = try await sut.eceView(mockECEViewController, didReceiveShippingRateChange: shippingRate)

        // Wait for handler
        await fulfillment(of: [expectation], timeout: 1.0)

        // Then
        XCTAssertTrue(handlerCalled)
        XCTAssertNil(response["error"])
        XCTAssertEqual(response["totalAmount"] as? Int, 4500) // Items (3000) + Original Express (1500)
    }

    func testShippingRateChange_InvalidRateId() async {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockConfiguration.apiClient)
        let shippingRate: [String: Any] = [
            "id": "invalid_rate_id",
            "amount": 100,
            "displayName": "Invalid Rate",
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
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - ECE Click Tests

    func testECEClick_ReturnsProperConfiguration() async throws {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockConfiguration.apiClient)
        let event = [
            "walletType": "shop_pay",
            "expressPaymentType": "shop_pay",
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
        let mockECEViewController = ECEViewController(apiClient: mockConfiguration.apiClient)
        let paymentDetails: [String: Any] = [
            "billingDetails": [
                "email": "test@example.com",
                "phone": "+14155551234",
                "name": "John Doe",
            ],
            "shippingAddress": ["address1": "123 Main St"],
            "shippingRate": ["id": "standard", "amount": 100, "displayName": "Standard Shipping"],
            "mode": "payment",
            "captureMethod": "automatic",
        ]

        // When
        let response = try await sut.eceView(mockECEViewController, didReceiveECEConfirmation: paymentDetails)

        // Then
        XCTAssertEqual(response["status"] as? String, "success")
        XCTAssertEqual(response["requiresAction"] as? Bool, false)
    }

    func testECEConfirmation_MissingBillingDetails() async {
        // Given
        let mockECEViewController = ECEViewController(apiClient: mockConfiguration.apiClient)
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
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

}
