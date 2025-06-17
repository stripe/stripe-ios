//
//  PaymentSheetFlowControllerTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 6/13/25.
//

@testable import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(AppearanceAPIAdditionsPreview) @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
import XCTest

class PaymentSheetFlowControllerTests: XCTestCase {

    // MARK: - PaymentOptionDisplayData Labels Tests

    func testPaymentOptionDisplayData_CardLabels() {
        // Create a Visa card payment option
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 12
        cardParams.expYear = 2030
        cardParams.cvc = "123"

        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = cardParams

        let paymentOption = PaymentSheet.PaymentOption.new(confirmParams: confirmParams)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for card payment option
        XCTAssertEqual(displayData.labels.label, "Visa")
        XCTAssertEqual(displayData.labels.sublabel, "•••• 4242")
    }

    func testPaymentOptionDisplayData_USBankAccountLabels_NoLinkedBank() {
        // Create a US bank account payment option without linked bank
        let bankParams = STPPaymentMethodUSBankAccountParams()
        bankParams.accountType = .checking
        bankParams.accountHolderType = .individual

        let confirmParams = IntentConfirmParams(type: .stripe(.USBankAccount))
        confirmParams.paymentMethodParams.usBankAccount = bankParams

        let paymentOption = PaymentSheet.PaymentOption.new(confirmParams: confirmParams)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for US bank account without linked bank
        XCTAssertEqual(displayData.labels.label, "US bank account")
        XCTAssertNil(displayData.labels.sublabel)
    }

    func testPaymentOptionDisplayData_SavedCardLabels() {
        // Create a saved Visa card payment method using test helper
        let paymentMethod = STPPaymentMethod._testCard()

        let paymentOption = PaymentSheet.PaymentOption.saved(paymentMethod: paymentMethod, confirmParams: nil)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for saved card
        XCTAssertEqual(displayData.labels.label, "Visa")
        XCTAssertEqual(displayData.labels.sublabel, "•••• 4242")
    }

    func testPaymentOptionDisplayData_SavedUSBankAccountLabels() {
        // Create a saved US bank account payment method using test helper
        let paymentMethod = STPPaymentMethod._testUSBankAccount()

        let paymentOption = PaymentSheet.PaymentOption.saved(paymentMethod: paymentMethod, confirmParams: nil)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for saved US bank account - should show bank name from saved payment method
        XCTAssertEqual(displayData.labels.label, "STRIPE TEST BANK")
        XCTAssertEqual(displayData.labels.sublabel, "••••6789")
    }

    func testPaymentOptionDisplayData_ApplePayLabels() {
        let paymentOption = PaymentSheet.PaymentOption.applePay
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for Apple Pay
        XCTAssertEqual(displayData.labels.label, "Apple Pay")
        XCTAssertEqual(displayData.labels.sublabel, nil)
    }

    func testPaymentOptionDisplayData_LinkLabels() {
        let linkOption = PaymentSheet.LinkConfirmOption.wallet
        let paymentOption = PaymentSheet.PaymentOption.link(option: linkOption)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for Link
        XCTAssertEqual(displayData.labels.label, STPPaymentMethodType.link.displayName)
        XCTAssertNil(displayData.labels.sublabel)
    }

    func testPaymentOptionDisplayData_ExternalPaymentMethodLabels() {
        // Create an external payment method (e.g., PayPal)
        let externalPaymentMethod = ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: URL(string: "https://example.com/paypal.png")!,
            darkImageUrl: nil
        )

        let configuration = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { _, _, completion in
                completion(.completed)
            }
        )

        let externalPaymentOption = ExternalPaymentOption.from(externalPaymentMethod, configuration: configuration)!
        let billingDetails = STPPaymentMethodBillingDetails()

        let paymentOption = PaymentSheet.PaymentOption.external(paymentMethod: externalPaymentOption, billingDetails: billingDetails)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for external payment method
        XCTAssertEqual(displayData.labels.label, "PayPal")
        XCTAssertEqual(displayData.labels.sublabel, nil)
    }

    func testPaymentOptionDisplayData_SavedLinkCardLabels() {
        // Create a saved Link card payment method using test helper
        let paymentMethod = STPPaymentMethod._testLink()

        let paymentOption = PaymentSheet.PaymentOption.saved(paymentMethod: paymentMethod, confirmParams: nil)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for saved Link card - should show Link display name as label and detailed info as sublabel
        XCTAssertEqual(displayData.labels.label, STPPaymentMethodType.link.displayName)
        XCTAssertEqual(displayData.labels.sublabel, "•••• 4242")
    }

    func testPaymentOptionDisplayData_SavedLinkPaymentMethodLabels() {
        // Create a saved Link payment method using test helper
        let paymentMethod = STPPaymentMethod._testLink()

        let paymentOption = PaymentSheet.PaymentOption.saved(paymentMethod: paymentMethod, confirmParams: nil)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for saved Link payment method - display name is nil on fixture so should show "Link"
        XCTAssertEqual(displayData.labels.label, "Link")
        XCTAssertEqual(displayData.labels.sublabel, "•••• 4242")
    }
}
