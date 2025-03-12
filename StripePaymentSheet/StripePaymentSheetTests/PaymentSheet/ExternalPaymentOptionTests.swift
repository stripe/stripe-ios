//
//  ExternalPaymentOptionTests.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/12/25.
//

@_spi(STP) import StripeCore
@testable @_spi(CustomPaymentMethodsBeta) import StripePaymentSheet
import XCTest

class ExternalPaymentOptionTests: XCTestCase {
    
    // MARK: - Test Data
    
    let mockBillingDetails = STPPaymentMethodBillingDetails()
    let mockLightImageURL = URL(string: "https://example.com/light.png")!
    let mockDarkImageURL = URL(string: "https://example.com/dark.png")!
    
    // Mock External Payment Method
    func createMockExternalPaymentMethod() -> ExternalPaymentMethod {
        return ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: mockLightImageURL,
            darkImageUrl: mockDarkImageURL
        )
    }
    
    // Mock Custom Payment Method
    func createMockCustomPaymentMethod() -> CustomPaymentMethod {
        return CustomPaymentMethod(
            displayName: "Apple Pay",
            type: "cpmt_apple_pay",
            logoUrl: mockLightImageURL,
            isPreset: true,
            error: nil
        )
    }
    
    // MARK: - Tests for Factory Methods
    
    func testFromExternalPaymentMethod_Success() {
        // Given
        let mockExternalPaymentMethod = createMockExternalPaymentMethod()
        let expectation = self.expectation(description: "Confirm handler called")
        
        let mockConfiguration = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { type, billingDetails, completion in
                XCTAssertEqual(type, "external_paypal")
                XCTAssertEqual(billingDetails, self.mockBillingDetails)
                completion(.completed)
                expectation.fulfill()
            }
        )
        
        // When
        let paymentOption = ExternalPaymentOption.from(mockExternalPaymentMethod, configuration: mockConfiguration)
        
        // Then
        XCTAssertNotNil(paymentOption)
        XCTAssertEqual(paymentOption?.type, "external_paypal")
        XCTAssertEqual(paymentOption?.displayText, "PayPal")
        XCTAssertNil(paymentOption?.displaySubtext)
        XCTAssertEqual(paymentOption?.lightImageUrl, mockLightImageURL)
        XCTAssertEqual(paymentOption?.darkImageUrl, mockDarkImageURL)
        
        // Test confirm handler works
        paymentOption?.confirm(billingDetails: mockBillingDetails) { _ in }
        waitForExpectations(timeout: 0.1)
    }
    
    func testFromCustomPaymentMethod_Success() {
        // Given
        let mockCustomPaymentMethod = createMockCustomPaymentMethod()
        let expectation = self.expectation(description: "Custom confirm handler called")
        
        let mockCustomType = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethodType(
            id: "cpmt_apple_pay",
            subcopy: "Fast and secure checkout"
        )
        
        let mockConfiguration = PaymentSheet.CustomPaymentMethodConfiguration(
            customPaymentMethodTypes: [mockCustomType],
            customPaymentMethodConfirmHandler: { cpmType, billingDetails in
                XCTAssertEqual(cpmType.id, "cpmt_apple_pay")
                XCTAssertEqual(cpmType.subcopy, "Fast and secure checkout")
                XCTAssertEqual(billingDetails, self.mockBillingDetails)
                expectation.fulfill()
                return .completed
            }
        )
        
        // When
        let paymentOption = ExternalPaymentOption.from(mockCustomPaymentMethod, configuration: mockConfiguration)
        
        // Then
        XCTAssertNotNil(paymentOption)
        XCTAssertEqual(paymentOption?.type, "cpmt_apple_pay")
        XCTAssertEqual(paymentOption?.displayText, "Apple Pay")
        XCTAssertEqual(paymentOption?.displaySubtext, "Fast and secure checkout")
        XCTAssertEqual(paymentOption?.lightImageUrl, mockLightImageURL)
        XCTAssertNil(paymentOption?.darkImageUrl)
        
        // Test confirm handler works
        paymentOption?.confirm(billingDetails: mockBillingDetails) { _ in }
        waitForExpectations(timeout: 0.1)
    }
    
    // MARK: - Tests for Confirm Method
    
    func testConfirm_CustomPaymentMethod() {
        // Given
        let mockCustomPaymentMethod = createMockCustomPaymentMethod()
        let confirmExpectation = self.expectation(description: "Custom confirm handler called")
        let completionExpectation = self.expectation(description: "Completion handler called")
        
        let mockCustomType = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethodType(
            id: "cpmt_apple_pay",
            subcopy: "Fast and secure checkout"
        )
        
        let mockConfiguration = PaymentSheet.CustomPaymentMethodConfiguration(
            customPaymentMethodTypes: [mockCustomType],
            customPaymentMethodConfirmHandler: { customType, billingDetails in
                // Validate the parameters passed to the confirm handler
                XCTAssertEqual(customType.id, "cpmt_apple_pay")
                XCTAssertEqual(billingDetails, self.mockBillingDetails)
                confirmExpectation.fulfill()
                return .completed
            }
        )
        
        guard let paymentOption = ExternalPaymentOption.from(mockCustomPaymentMethod, configuration: mockConfiguration) else {
            XCTFail("Failed to create payment option")
            return
        }
        
        // When
        paymentOption.confirm(billingDetails: mockBillingDetails) { result in
            XCTAssertEqual(result, .completed)
            completionExpectation.fulfill()
        }
        
        // Then
        waitForExpectations(timeout: 0.1)
    }
    
    func testConfirm_ExternalPaymentMethod() {
        // Given
        let mockExternalPaymentMethod = createMockExternalPaymentMethod()
        let confirmExpectation = self.expectation(description: "External confirm handler called")
        let completionExpectation = self.expectation(description: "Completion handler called")
        
        let mockConfiguration = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { type, billingDetails, completion in
                // Validate the parameters passed to the confirm handler
                XCTAssertEqual(type, "external_paypal")
                XCTAssertEqual(billingDetails, self.mockBillingDetails)
                confirmExpectation.fulfill()
                completion(.completed)
            }
        )
        
        guard let paymentOption = ExternalPaymentOption.from(mockExternalPaymentMethod, configuration: mockConfiguration) else {
            XCTFail("Failed to create payment option")
            return
        }
        
        // When
        paymentOption.confirm(billingDetails: mockBillingDetails) { result in
            XCTAssertEqual(result, .completed)
            completionExpectation.fulfill()
        }
        
        // Then
        waitForExpectations(timeout: 0.1)
    }
    
    func testConfirm_ExternalPaymentMethod_Cancellation() {
        // Given
        let mockExternalPaymentMethod = createMockExternalPaymentMethod()
        let confirmExpectation = self.expectation(description: "External confirm handler called")
        let completionExpectation = self.expectation(description: "Completion handler called")
        
        let mockConfiguration = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { _, _, completion in
                confirmExpectation.fulfill()
                completion(.canceled)
            }
        )
        
        guard let paymentOption = ExternalPaymentOption.from(mockExternalPaymentMethod, configuration: mockConfiguration) else {
            XCTFail("Failed to create payment option")
            return
        }
        
        // When
        paymentOption.confirm(billingDetails: mockBillingDetails) { result in
            // Verify cancellation is passed through correctly
            XCTAssertEqual(result, .canceled)
            completionExpectation.fulfill()
        }
        
        // Then
        waitForExpectations(timeout: 0.1)
    }
    
    func testConfirm_CustomPaymentMethod_Error() {
        // Given
        let mockCustomPaymentMethod = createMockCustomPaymentMethod()
        let confirmExpectation = self.expectation(description: "Custom confirm handler called")
        let completionExpectation = self.expectation(description: "Completion handler called")
        
        let mockCustomType = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethodType(
            id: "cpmt_apple_pay",
            subcopy: "Fast and secure checkout"
        )
        
        let mockConfiguration = PaymentSheet.CustomPaymentMethodConfiguration(
            customPaymentMethodTypes: [mockCustomType],
            customPaymentMethodConfirmHandler: { _, _ in
                confirmExpectation.fulfill()
                return .failed(error: NSError(domain: "test", code: 123, userInfo: nil))
            }
        )
        
        guard let paymentOption = ExternalPaymentOption.from(mockCustomPaymentMethod, configuration: mockConfiguration) else {
            XCTFail("Failed to create payment option")
            return
        }
        
        // When
        paymentOption.confirm(billingDetails: mockBillingDetails) { result in
            if case .failed(let error) = result {
                XCTAssertEqual((error as NSError).code, 123)
                XCTAssertEqual((error as NSError).domain, "test")
            } else {
                XCTFail("Expected failed result but got \(result)")
            }
            completionExpectation.fulfill()
        }
        
        // Then
        waitForExpectations(timeout: 0.1)
    }
    
    // MARK: - Tests for Equatable and Hashable
    
    func testEquatable_SameType_Equal() {
        // Given
        let mockConfig = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { _, _, completion in completion(.completed) }
        )
        
        let mockExternalPaymentMethod1 = ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: URL(string: "https://example.com/light1.png")!,
            darkImageUrl: URL(string: "https://example.com/dark1.png")!
        )
        
        let mockExternalPaymentMethod2 = ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal Different Label", // Different label
            lightImageUrl: URL(string: "https://example.com/light2.png")!, // Different URL
            darkImageUrl: URL(string: "https://example.com/dark2.png")! // Different URL
        )
        
        // When
        let option1 = ExternalPaymentOption.from(mockExternalPaymentMethod1, configuration: mockConfig)
        let option2 = ExternalPaymentOption.from(mockExternalPaymentMethod2, configuration: mockConfig)
        
        // Then
        XCTAssertEqual(option1, option2, "Options with same type should be equal despite different properties")
    }
    
    func testEquatable_DifferentType_NotEqual() {
        // Given
        let mockConfig = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal", "external_klarna"],
            externalPaymentMethodConfirmHandler: { _, _, completion in completion(.completed) }
        )
        
        let mockExternalPaymentMethod1 = ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: mockLightImageURL,
            darkImageUrl: mockDarkImageURL
        )
        
        let mockExternalPaymentMethod2 = ExternalPaymentMethod(
            type: "external_klarna",
            label: "Klarna",
            lightImageUrl: mockLightImageURL,
            darkImageUrl: mockDarkImageURL
        )
        
        // When
        let option1 = ExternalPaymentOption.from(mockExternalPaymentMethod1, configuration: mockConfig)
        let option2 = ExternalPaymentOption.from(mockExternalPaymentMethod2, configuration: mockConfig)
        
        // Then
        XCTAssertNotEqual(option1, option2, "Options with different types should not be equal")
    }
    
    func testHashable_SameTypeHashesToSameValue() {
        // Given
        let mockConfig = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { _, _, completion in completion(.completed) }
        )
        
        let mockExternalPaymentMethod1 = ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: URL(string: "https://example.com/light1.png")!,
            darkImageUrl: URL(string: "https://example.com/dark1.png")!
        )
        
        let mockExternalPaymentMethod2 = ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal Different", // Different properties
            lightImageUrl: URL(string: "https://example.com/light2.png")!,
            darkImageUrl: nil // Different property
        )
        
        // When
        let option1 = ExternalPaymentOption.from(mockExternalPaymentMethod1, configuration: mockConfig)!
        let option2 = ExternalPaymentOption.from(mockExternalPaymentMethod2, configuration: mockConfig)!
        
       // Then
        XCTAssertEqual(
            option1.hashValue,
            option2.hashValue,
            "Options with same type should hash to same value"
        )
        
        // Test in a Set
        let optionSet = Set(
            [
                option1,
                option2
            ]
        )
        XCTAssertEqual(
            optionSet.count,
            1,
            "Set should only contain one item because options have same hash"
        )
        XCTAssertTrue(
            optionSet.contains(
                option1
            ),
            "Set should contain option1"
        )
        XCTAssertTrue(
            optionSet.contains(
                option2
            ),
            "Set should contain option2 (which is equal to option1)"
        )
    }
    
    func testHashable_DifferentTypeHashesToDifferentValue() {
        // Given
        let mockConfig = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: [
                "external_paypal",
                "external_klarna"
            ],
            externalPaymentMethodConfirmHandler: {
                _,
                _,
                completion in completion(
                    .completed
                )
            }
        )
        
        let mockExternalPaymentMethod1 = ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: mockLightImageURL,
            darkImageUrl: mockDarkImageURL
        )
        
        let mockExternalPaymentMethod2 = ExternalPaymentMethod(
            type: "external_klarna",
            label: "Klarna",
            lightImageUrl: mockLightImageURL,
            darkImageUrl: mockDarkImageURL
        )
        
        // When
        let option1 = ExternalPaymentOption.from(
            mockExternalPaymentMethod1,
            configuration: mockConfig
        )!
        let option2 = ExternalPaymentOption.from(
            mockExternalPaymentMethod2,
            configuration: mockConfig
        )!
        
        // Then
        XCTAssertNotEqual(
            option1.hashValue,
            option2.hashValue,
            "Options with different types should hash to different values"
        )
        
        // Test in a Set
        let optionSet = Set(
            [
                option1,
                option2
            ]
        )
        XCTAssertEqual(
            optionSet.count,
            2,
            "Set should contain two items because options have different hashes"
        )
        XCTAssertTrue(
            optionSet.contains(
                option1
            ),
            "Set should contain option1"
        )
        XCTAssertTrue(
            optionSet.contains(
                option2
            ),
            "Set should contain option2"
        )
    }
    
    func testHashable_UsageInDictionary() {
        // Given
        let mockConfig = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: [
                "external_paypal",
                "external_klarna"
            ],
            externalPaymentMethodConfirmHandler: {
                _,
                _,
                completion in completion(
                    .completed
                )
            }
        )
        
        let paypalMethod = ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: mockLightImageURL,
            darkImageUrl: mockDarkImageURL
        )
        
        let klarnaMethod = ExternalPaymentMethod(
            type: "external_klarna",
            label: "Klarna",
            lightImageUrl: mockLightImageURL,
            darkImageUrl: mockDarkImageURL
        )
        
        let paypalOption = ExternalPaymentOption.from(
            paypalMethod,
            configuration: mockConfig
        )!
        let klarnaOption = ExternalPaymentOption.from(
            klarnaMethod,
            configuration: mockConfig
        )!
        
        // Different object but same type as paypalOption
        let paypalOption2 = ExternalPaymentOption.from(
            ExternalPaymentMethod(
                type: "external_paypal",
                label: "Different Label",
                lightImageUrl: URL(
                    string: "https://example.com/different.png"
                )!,
                darkImageUrl: nil
            ),
            configuration: mockConfig
        )!
        
        // When
        var paymentOptions: [ExternalPaymentOption: String] = [:]
        paymentOptions[paypalOption] = "Value for PayPal"
        paymentOptions[klarnaOption] = "Value for Klarna"
        
        // Then
        XCTAssertEqual(
            paymentOptions.count,
            2,
            "Dictionary should have two entries"
        )
        XCTAssertEqual(
            paymentOptions[paypalOption],
            "Value for PayPal"
        )
        XCTAssertEqual(
            paymentOptions[klarnaOption],
            "Value for Klarna"
        )
        
        // When using an equivalent object with same type
        XCTAssertEqual(
            paymentOptions[paypalOption2],
            "Value for PayPal",
            "Should retrieve the same value using an equivalent object"
        )
        
        // When updating with equivalent object
        paymentOptions[paypalOption2] = "Updated PayPal Value"
        XCTAssertEqual(
            paymentOptions.count,
            2,
            "Dictionary should still have two entries"
        )
        XCTAssertEqual(
            paymentOptions[paypalOption],
            "Updated PayPal Value",
            "Original key should access updated value"
        )
        XCTAssertEqual(
            paymentOptions[paypalOption2],
            "Updated PayPal Value",
            "Equivalent key should access same updated value"
        )
   }
}
