//
//  LinkControllerConfirmationTokenTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class LinkControllerConfirmationTokenTests: XCTestCase {

    func testMakeConfirmationTokenParams_paymentModeUsesPaymentMethodAndShipping() {
        let params = LinkController.makeConfirmationTokenParams(
            paymentMethod: makeCardPaymentMethod(),
            mode: .payment,
            configuration: makeConfiguration()
        )

        XCTAssertEqual(params.paymentMethod, "pm_test_card")
        XCTAssertEqual(params.returnURL, "example://return")
        XCTAssertEqual(params.shipping?.name, "Jane Doe")
        XCTAssertEqual(params.shipping?.phone, "5551234567")
        XCTAssertEqual(params.shipping?.address.country, "US")
        XCTAssertEqual(params.shipping?.address.line1, "Line 1")
        XCTAssertEqual(params.setupFutureUsage, .none)
        XCTAssertNil(params.additionalAPIParameters["setup_future_usage"])
        XCTAssertNil(params.mandateData)
    }

    func testMakeConfirmationTokenParams_setupModesUseOffSession() {
        let paymentAndSetupFutureUseParams = LinkController.makeConfirmationTokenParams(
            paymentMethod: makeCardPaymentMethod(),
            mode: .paymentAndSetupFutureUse,
            configuration: makeConfiguration()
        )
        let setupParams = LinkController.makeConfirmationTokenParams(
            paymentMethod: makeCardPaymentMethod(),
            mode: .setup,
            configuration: makeConfiguration()
        )

        XCTAssertEqual(paymentAndSetupFutureUseParams.setupFutureUsage, .offSession)
        XCTAssertEqual(setupParams.setupFutureUsage, .offSession)
    }

    func testMakeConfirmationTokenParams_setupModeAddsMandateForUSBankAccount() {
        let params = LinkController.makeConfirmationTokenParams(
            paymentMethod: makeUSBankAccountPaymentMethod(),
            mode: .setup,
            configuration: makeConfiguration()
        )

        XCTAssertEqual(params.setupFutureUsage, .offSession)
        XCTAssertNotNil(params.mandateData)
    }

    private func makeConfiguration() -> PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "example://return"
        configuration.shippingDetails = {
            .init(
                address: .init(
                    country: "US",
                    line1: "Line 1"
                ),
                name: "Jane Doe",
                phone: "5551234567"
            )
        }
        return configuration
    }

    private func makeCardPaymentMethod() -> STPPaymentMethod {
        STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_test_card",
            "created": "12345",
            "type": "card",
            "card": [
                "brand": "visa",
                "last4": "4242",
                "exp_month": 12,
                "exp_year": 2030,
            ],
        ])!
    }

    private func makeUSBankAccountPaymentMethod() -> STPPaymentMethod {
        STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_test_us_bank",
            "created": "12345",
            "type": "us_bank_account",
            "us_bank_account": [
                "account_type": "checking",
                "account_holder_type": "individual",
                "last4": "6789",
                "routing_number": "110000000",
            ],
        ])!
    }
}
