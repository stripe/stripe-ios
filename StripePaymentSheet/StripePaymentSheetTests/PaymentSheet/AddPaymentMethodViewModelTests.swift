//
//  AddPaymentMethodViewModelTests.swift
//  StripePaymentSheetTests
//
//  Created by Eduardo Urias on 9/4/23.
//

import Foundation
@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) @testable import StripeUICore
import XCTest

// Marked as MainActor because some elements perform UI actions, these should be removed during the refactoring process.
@MainActor
class AddPaymentMethodViewModelTests: XCTestCase {
    override func setUp() async throws {
        await PaymentSheetLoader.loadMiscellaneousSingletons()
    }

    func testPaymentMethodElementChanges() async throws {
        let intent = Intent.paymentIntent(STPFixtures.paymentIntent(paymentMethodTypes: ["klarna", "card", "cashapp"]))
        let config = PaymentSheet.Configuration._testValue_MostPermissive()
        let viewModel = AddPaymentMethodViewModel(intent: intent, configuration: config)

        viewModel.paymentMethodTypeSelectorViewModel.selected = .card

        var form = viewModel.paymentMethodFormElement
        XCTAssertNotNil(form.getTextFieldElement("Card number"))
        XCTAssertNotNil(form.getTextFieldElement("MM / YY"))
        XCTAssertNotNil(form.getTextFieldElement("CVC"))

        viewModel.paymentMethodTypeSelectorViewModel.selected = .dynamic("klarna")
        form = viewModel.paymentMethodFormElement
        XCTAssertNotNil(form.getTextFieldElement("Email"))
        XCTAssertNotNil(form.getDropdownFieldElement("Country or region"))
    }

    func testPaymentOption() {
        let intent = Intent.paymentIntent(STPFixtures.paymentIntent(paymentMethodTypes: ["card"]))
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.billingDetailsCollectionConfiguration.address = .never
        let viewModel = AddPaymentMethodViewModel(intent: intent, configuration: config)

        let form = viewModel.paymentMethodFormElement
        form.getTextFieldElement("Card number")?.setText("4242424242424242")
        form.getTextFieldElement("MM / YY")?.setText("01/33")
        form.getTextFieldElement("CVC")?.setText("123")

        guard case .new(let params) = viewModel.paymentOption else {
            XCTFail("Wrong payment option")
            return
        }

        XCTAssertEqual(params.paymentMethodType, .card)
        XCTAssertEqual(params.paymentMethodParams.card?.number, "4242424242424242")
        XCTAssertEqual(params.paymentMethodParams.card?.expMonth, 1)
        XCTAssertEqual(params.paymentMethodParams.card?.expYear, 33)
        XCTAssertEqual(params.paymentMethodParams.card?.cvc, "123")
    }

    func testLinkPaymentOption() throws {
        let intent = Intent.paymentIntent(STPFixtures.paymentIntent(
            paymentMethodTypes: ["link", "card"],
            linkSettings: ["link_funding_sources": ["CARD"]]
        ))
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.billingDetailsCollectionConfiguration.address = .never
        let viewModel = AddPaymentMethodViewModel(intent: intent, configuration: config, isLinkEnabled: true)

        let testLinkAccount = PaymentSheetLinkAccount(
            email: "user@example.com",
            session: nil,
            publishableKey: nil
        )
        LinkAccountContext.shared.account = testLinkAccount

        let form = try XCTUnwrap(viewModel.paymentMethodFormElement as? LinkEnabledPaymentMethodElement)
        form.getTextFieldElement("Card number")?.setText("4242424242424242")
        form.getTextFieldElement("MM / YY")?.setText("01/33")
        form.getTextFieldElement("CVC")?.setText("123")
        form.inlineSignupElement.viewModel.saveCheckboxChecked = true
        form.inlineSignupElement.viewModel.legalName = "Jane Doe"
        form.inlineSignupElement.viewModel.emailAddress = "user@example.com"
        form.inlineSignupElement.viewModel.phoneNumber = .fromE164("+14105551234")

        guard case .link(let option) = viewModel.paymentOption else {
            XCTFail("Wrong payment option")
            return
        }

        XCTAssertEqual(option.account, testLinkAccount)
    }

    func testUSBankAccountFormElement() throws {
        let intent = Intent.paymentIntent(STPFixtures.paymentIntent(
            paymentMethodTypes: ["card", "us_bank_account"],
            paymentMethodOptions: ["us_bank_account": ["verification_method": "automatic"]]
        ))
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.allowsDelayedPaymentMethods = true
        let viewModel = AddPaymentMethodViewModel(intent: intent, configuration: config)
        viewModel.paymentMethodTypeSelectorViewModel.selected = .USBankAccount

        let form = viewModel.paymentMethodFormElement
        XCTAssertIs(form, USBankAccountPaymentMethodElement.self)
    }

    func testExternalPaypalPaymentOption() throws {
        let intent = Intent.paymentIntent(STPFixtures.paymentIntent(paymentMethodTypes: ["card", "external_paypal"]))
        let config = PaymentSheet.Configuration._testValue_MostPermissive()
        let viewModel = AddPaymentMethodViewModel(intent: intent, configuration: config)

        viewModel.paymentMethodTypeSelectorViewModel.selected = .externalPayPal
        guard case .externalPayPal = viewModel.paymentOption else {
            XCTFail("Wrong payment option")
            return
        }
    }
}
