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
            displayName: "Test CPM",
            type: "cpmt_1234",
            logoUrl: mockLightImageURL,
            isPreset: true,
            error: nil
        )
    }

    // MARK: - Tests `from` functions

    func testFromExternalPaymentMethod_Success() async {
        let mockExternalPaymentMethod = createMockExternalPaymentMethod()
        let expectation = self.expectation(description: "Confirm handler called")

        let mockConfiguration = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { type, billingDetails in
                XCTAssertEqual(type, "external_paypal")
                XCTAssertEqual(billingDetails, self.mockBillingDetails)
                expectation.fulfill()
                return .completed
            }
        )

        let paymentOption = ExternalPaymentOption.from(mockExternalPaymentMethod, configuration: mockConfiguration)

        XCTAssertNotNil(paymentOption)
        XCTAssertEqual(paymentOption?.type, "external_paypal")
        XCTAssertEqual(paymentOption?.displayText, "PayPal")
        XCTAssertNil(paymentOption?.displaySubtext)
        XCTAssertEqual(paymentOption?.lightImageUrl, mockLightImageURL)
        XCTAssertEqual(paymentOption?.darkImageUrl, mockDarkImageURL)
        XCTAssertFalse(paymentOption?.disableBillingDetailCollection ?? true)

        // Test confirm handler works
        _ = await paymentOption?.confirm(billingDetails: mockBillingDetails)
        await fulfillment(of: [expectation])
    }

    func testFromCustomPaymentMethod_Success() async {
        let mockCustomPaymentMethod = createMockCustomPaymentMethod()
        let expectation = self.expectation(description: "Custom confirm handler called")

        let mockCustomType = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethod(
            id: "cpmt_1234",
            subtitle: "Fast and secure checkout"
        )

        let mockConfiguration = PaymentSheet.CustomPaymentMethodConfiguration(
            customPaymentMethods: [mockCustomType],
            customPaymentMethodConfirmHandler: { cpmType, billingDetails in
                XCTAssertEqual(cpmType.id, "cpmt_1234")
                XCTAssertEqual(cpmType.subtitle, "Fast and secure checkout")
                XCTAssertEqual(billingDetails, self.mockBillingDetails)
                expectation.fulfill()
                return .completed
            }
        )

        let paymentOption = ExternalPaymentOption.from(mockCustomPaymentMethod, configuration: mockConfiguration)

        XCTAssertNotNil(paymentOption)
        XCTAssertEqual(paymentOption?.type, "cpmt_1234")
        XCTAssertEqual(paymentOption?.displayText, "Test CPM")
        XCTAssertEqual(paymentOption?.displaySubtext, "Fast and secure checkout")
        XCTAssertEqual(paymentOption?.lightImageUrl, mockLightImageURL)
        XCTAssertNil(paymentOption?.darkImageUrl)
        XCTAssertTrue(paymentOption?.disableBillingDetailCollection ?? false)

        // Test confirm handler works
        _ = await paymentOption?.confirm(billingDetails: mockBillingDetails)
        await fulfillment(of: [expectation])
    }

    // MARK: - Tests for Confirm Method

    func testConfirm_CustomPaymentMethod() async {
        let mockCustomPaymentMethod = createMockCustomPaymentMethod()
        let confirmExpectation = self.expectation(description: "Custom confirm handler called")

        let mockCustomType = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethod(
            id: "cpmt_1234",
            subtitle: "Fast and secure checkout"
        )

        let mockConfiguration = PaymentSheet.CustomPaymentMethodConfiguration(
            customPaymentMethods: [mockCustomType],
            customPaymentMethodConfirmHandler: { customType, billingDetails in
                XCTAssertEqual(customType.id, "cpmt_1234")
                XCTAssertEqual(billingDetails, self.mockBillingDetails)
                confirmExpectation.fulfill()
                return .completed
            }
        )

        guard let paymentOption = ExternalPaymentOption.from(mockCustomPaymentMethod, configuration: mockConfiguration) else {
            XCTFail("Failed to create external payment option")
            return
        }

        let result = await paymentOption.confirm(billingDetails: mockBillingDetails)
        XCTAssertEqual(result, .completed)
        await fulfillment(of: [confirmExpectation])
    }

    func testConfirm_ExternalPaymentMethod() async {
        let mockExternalPaymentMethod = createMockExternalPaymentMethod()
        let confirmExpectation = self.expectation(description: "External confirm handler called")

        let mockConfiguration = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { type, billingDetails in
                XCTAssertEqual(type, "external_paypal")
                XCTAssertEqual(billingDetails, self.mockBillingDetails)
                confirmExpectation.fulfill()
                return .completed
            }
        )

        guard let paymentOption = ExternalPaymentOption.from(mockExternalPaymentMethod, configuration: mockConfiguration) else {
            XCTFail("Failed to create external payment option")
            return
        }

        let result = await paymentOption.confirm(billingDetails: mockBillingDetails)
        XCTAssertEqual(result, .completed)
        await fulfillment(of: [confirmExpectation])
    }

    func testConfirm_ExternalPaymentMethod_Cancellation() async {
        let mockExternalPaymentMethod = createMockExternalPaymentMethod()
        let confirmExpectation = self.expectation(description: "External confirm handler called")

        let mockConfiguration = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { _, _ in
                confirmExpectation.fulfill()
                return .canceled
            }
        )

        guard let paymentOption = ExternalPaymentOption.from(mockExternalPaymentMethod, configuration: mockConfiguration) else {
            XCTFail("Failed to create external payment option")
            return
        }

        let result = await paymentOption.confirm(billingDetails: mockBillingDetails)
        XCTAssertEqual(result, .canceled)

        await fulfillment(of: [confirmExpectation])
    }

    // MARK: - Tests for Equatable and Hashable

    func testEquatable_SameType_Equal() {
        let mockConfig = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { _, _ in return .completed }
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

        let option1 = ExternalPaymentOption.from(mockExternalPaymentMethod1, configuration: mockConfig)
        let option2 = ExternalPaymentOption.from(mockExternalPaymentMethod2, configuration: mockConfig)

        XCTAssertEqual(option1, option2, "Options with same type should be equal despite different properties")
    }

    func testEquatable_DifferentType_NotEqual() {
        let mockConfig = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal", "external_klarna"],
            externalPaymentMethodConfirmHandler: { _, _ in return .completed }
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

        let option1 = ExternalPaymentOption.from(mockExternalPaymentMethod1, configuration: mockConfig)
        let option2 = ExternalPaymentOption.from(mockExternalPaymentMethod2, configuration: mockConfig)

        XCTAssertNotEqual(option1, option2, "Options with different types should not be equal")
    }

    func testHashable_UsageInDictionary() {
        let mockConfig = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: [
                "external_paypal",
                "external_klarna",
            ],
            externalPaymentMethodConfirmHandler: { _, _ in return .completed }
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

        var paymentOptions: [ExternalPaymentOption: String] = [:]
        paymentOptions[paypalOption] = "Value for PayPal"
        paymentOptions[klarnaOption] = "Value for Klarna"

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
