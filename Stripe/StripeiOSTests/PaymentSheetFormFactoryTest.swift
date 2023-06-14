//
//  PaymentSheetFormFactoryTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
@testable@_spi(STP) import StripeUICore
@testable@_spi(STP) import StripeUICore

class MockElement: Element {
    var paramsUpdater: (IntentConfirmParams) -> IntentConfirmParams?

    init(
        paramsUpdater: @escaping (IntentConfirmParams) -> IntentConfirmParams?
    ) {
        self.paramsUpdater = paramsUpdater
    }

    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        return paramsUpdater(params)
    }

    weak var delegate: ElementDelegate?
    lazy var view: UIView = { UIView() }()
}

class PaymentSheetFormFactoryTest: XCTestCase {
    func testUpdatesParams() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "Name"
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("sepa_debit")
        )
        let name = factory.makeName()
        let email = factory.makeEmail()
        let checkbox = factory.makeSaveCheckbox { _ in }

        let form = FormElement(elements: [name, email, checkbox])
        let params = form.updateParams(params: IntentConfirmParams(type: .dynamic("sepa_debit")))

        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.name, "Name")
        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.email, "email@stripe.com")
        XCTAssertEqual(params?.paymentMethodParams.type, .SEPADebit)
        XCTAssertEqual(params?.paymentMethodType, .dynamic("sepa_debit"))
    }

    func testSpecFromJSONProvider() {
        let e = expectation(description: "Loads form specs file")
        let provider = FormSpecProvider()
        provider.load { loaded in
            XCTAssertTrue(loaded)
            e.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("eps")
        )

        guard let spec = factory.specFromJSONProvider(provider: provider) else {
            XCTFail("Unable to load EPS Spec")
            return
        }

        XCTAssertEqual(spec.fields.count, 5)
        XCTAssertEqual(
            spec.fields.first,
            .name(FormSpec.NameFieldSpec(apiPath: ["v1": "billing_details[name]"], translationId: nil))
        )
        XCTAssertEqual(spec.type, "eps")
    }

    func testNameOverrideApiPathBySpec() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method")
        )
        let name = factory.makeName(apiPath: "custom_location[name]")
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = name.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.name)
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"]
                as! String,
            "someName"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)

        // Using the params as previous customer input...
        let name_with_previous_customer_input = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method"),
            previousCustomerInput: updatedParams
        ).makeName(apiPath: "custom_location[name]")
        // ...should result in a valid element filled out with the previous customer input
        XCTAssertEqual(name_with_previous_customer_input.element.text, "someName")
        XCTAssertEqual(name_with_previous_customer_input.validationState, .valid)
    }

    func testNameValueWrittenToDefaultLocation() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method")
        )
        let name = factory.makeName()
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = name.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.name, "someName")
        XCTAssertNil(
            updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"]
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)

        // Using the params as previous customer input...
        let name_with_previous_customer_input = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method"),
            previousCustomerInput: updatedParams
        ).makeName()
        // ...should result in a valid element filled out with the previous customer input
        XCTAssertEqual(name_with_previous_customer_input.element.text, "someName")
        XCTAssertEqual(name_with_previous_customer_input.validationState, .valid)
    }

    func testNameValueWrittenToLocationDefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method")
        )
        let nameSpec = FormSpec.NameFieldSpec(
            apiPath: ["v1": "custom_location[name]"],
            translationId: nil
        )
        let spec = FormSpec(
            type: "mock_pm",
            async: false,
            fields: [.name(nameSpec)],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.name)
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"]
                as! String,
            "someName"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)
    }

    func testNameValueWrittenToLocationUndefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method")
        )
        let nameSpec = FormSpec.NameFieldSpec(apiPath: nil, translationId: nil)
        let spec = FormSpec(
            type: "mock_pm",
            async: false,
            fields: [.name(nameSpec)],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(
            updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"]
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.name, "someName")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)
    }

    func testEmailOverrideApiPathBySpec() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method")
        )
        let email = factory.makeEmail(apiPath: "custom_location[email]")
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = email.updateParams(params: params)

        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"]
                as! String,
            "email@stripe.com"
        )
        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.email)
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)

        // Using the params as previous customer input...
        let email_with_previous_customer_input = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method"),
            previousCustomerInput: updatedParams
        ).makeName(apiPath: "custom_location[email]")
        // ...should result in a valid element filled out with the previous customer input
        XCTAssertEqual(email_with_previous_customer_input.element.text, "email@stripe.com")
        XCTAssertEqual(email_with_previous_customer_input.validationState, .valid)
    }

    func testEmailValueWrittenToDefaultLocation() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method")
        )
        let email = factory.makeEmail()
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = email.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.email, "email@stripe.com")
        XCTAssertNil(
            updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"]
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)

        // Using the params as previous customer input...
        let email_with_previous_customer_input = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method"),
            previousCustomerInput: updatedParams
        ).makeEmail()
        // ...should result in a valid element filled out with the previous customer input
        XCTAssertEqual(email_with_previous_customer_input.element.text, "email@stripe.com")
        XCTAssertEqual(email_with_previous_customer_input.validationState, .valid)
    }

    func testEmailValueWrittenToLocationDefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method")
        )
        let emailSpec = FormSpec.BaseFieldSpec(apiPath: ["v1": "custom_location[email]"])
        let spec = FormSpec(
            type: "mock_pm",
            async: false,
            fields: [.email(emailSpec)],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.email)
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"]
                as! String,
            "email@stripe.com"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)
    }

    func testPhoneValueWrittenToDefaultLocation() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.phone = "+15555555555"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method")
        )
        let phoneElement = factory.makePhone()
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = phoneElement.updateParams(params: params)

        XCTAssertEqual(
            updatedParams?.paymentMethodParams.billingDetails?.phone,
            "+15555555555"
        )

        // Using the params as previous customer input...
        let phone_with_previous_customer_input = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method"),
            previousCustomerInput: updatedParams
        ).makePhone()
        // ...should result in a valid element filled out with the previous customer input
        XCTAssertEqual(phone_with_previous_customer_input.element.selectedCountryCode, "US")
        XCTAssertEqual(phone_with_previous_customer_input.validationState, .valid)
    }

    func testEmailValueWrittenToLocationUndefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mock_payment_method")
        )

        let emailSpec = FormSpec.BaseFieldSpec(apiPath: nil)
        let spec = FormSpec(
            type: "mock_pm",
            async: false,
            fields: [.email(emailSpec)],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.email, "email@stripe.com")
        XCTAssertNil(
            updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"]
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)
    }

    func testMakeFormElement_dropdown() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("sepa_debit")
        )
        let selectorSpec = FormSpec.SelectorSpec(
            translationId: .eps_bank,
            items: [
                .init(displayText: "d1", apiValue: "123"),
                .init(displayText: "d2", apiValue: "456"),
            ],
            apiPath: ["v1": "custom_location[selector]"]
        )
        let spec = FormSpec(
            type: "sepa_debit",
            async: false,
            fields: [.selector(selectorSpec)],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("sepa_debit"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[selector]"]
                as! String,
            "123"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sepa_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .SEPADebit)

        // Given a dropdown...
        let dropdown = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("sepa_debit")
        ).makeDropdown(for: selectorSpec)
        // ...with a selection *different* from the default of 0
        dropdown.element.select(index: 1)
        // ...using the params as previous customer input to create a new dropdown...
        let previousCustomerInput = dropdown.updateParams(params: IntentConfirmParams(type: .dynamic("sepa_debit")))
        let dropdown_with_previous_customer_input = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("sepa_debit"),
            previousCustomerInput: previousCustomerInput
        ).makeDropdown(for: selectorSpec)

        // ...should result in a valid element filled out with the previous customer input
        XCTAssertEqual(dropdown_with_previous_customer_input.element.selectedIndex, 1)
        XCTAssertEqual(dropdown_with_previous_customer_input.validationState, .valid)
    }

    func testMakeFormElement_KlarnaCountry_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("klarna")
        )
        let spec = FormSpec(
            type: "klarna",
            async: false,
            fields: [.klarna_country(.init(apiPath: nil))],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("klarna"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.country, "US")
        XCTAssertNil(
            updatedParams?.paymentMethodParams.additionalAPIParameters[
                "billing_details[address][country]"
            ]
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "klarna")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .klarna)
    }

    func testMakeFormElement_KlarnaCountry_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("klarna")
        )
        let spec = FormSpec(
            type: "klarna",
            async: false,
            fields: [.klarna_country(.init(apiPath: ["v1": "billing_details[address][country]"]))],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("klarna"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.address?.country)
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters[
                "billing_details[address][country]"
            ] as! String,
            "US"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "klarna")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .klarna)
    }

    func testMakeFormElement_BSBNumber() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit")
        )
        let bsb = factory.makeBSB(apiPath: nil)
        bsb.element.setText("000-000")

        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        let updatedParams = bsb.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.auBECSDebit?.bsbNumber, "000000")
        XCTAssertNil(
            updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[bsb_number]"]
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
        // Using the params as previous customer input...
        let bsb_with_previous_input = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit"),
            previousCustomerInput: updatedParams
        ).makeBSB()
        // ...should result in a valid, filled out element
        XCTAssert(bsb_with_previous_input.validationState == .valid)
        let updatedParams_with_previous_input = bsb_with_previous_input.updateParams(params: .init(type: .dynamic("au_becs_debit")))
        XCTAssertEqual(updatedParams_with_previous_input?.paymentMethodParams.auBECSDebit?.bsbNumber, "000000")
    }

    func testMakeFormElement_BSBNumber_withAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit")
        )
        let bsb = factory.makeBSB(apiPath: "custom_path[bsb_number]")
        bsb.element.setText("000-000")

        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        let updatedParams = bsb.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.auBECSDebit?.bsbNumber)
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters["custom_path[bsb_number]"]
                as! String,
            "000000"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
        // Using the params as previous customer input...
        let bsb_with_previous_input = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit"),
            previousCustomerInput: updatedParams
        ).makeBSB(apiPath: "custom_path[bsb_number]")
        // ...should result in a valid, filled out element
        XCTAssert(bsb_with_previous_input.validationState == .valid)
        let updatedParams_with_previous_input = bsb_with_previous_input.updateParams(params: .init(type: .dynamic("au_becs_debit")))
        XCTAssertEqual(
            updatedParams_with_previous_input?.paymentMethodParams.additionalAPIParameters["custom_path[bsb_number]"]
                as! String,
            "000000"
        )
    }

    func testMakeFormElement_BSBNumber_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit")
        )
        let spec = FormSpec(
            type: "au_becs_debit",
            async: false,
            fields: [.au_becs_bsb_number(.init(apiPath: nil))],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement.element) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("000-000")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.auBECSDebit?.bsbNumber, "000000")
        XCTAssertNil(
            updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[bsb_number]"]
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)

        // Using the params as previous customer input...
        let bsb_with_previous_input = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit"),
            previousCustomerInput: updatedParams
        ).makeBSB()
        // ...should result in a valid, filled out element
        XCTAssert(bsb_with_previous_input.validationState == .valid)
        let updatedParams_with_previous_input = bsb_with_previous_input.updateParams(params: .init(type: .dynamic("au_becs_debit")))
        XCTAssertEqual(updatedParams_with_previous_input?.paymentMethodParams.auBECSDebit?.bsbNumber, "000000")
    }

    func testMakeFormElement_BSBNumber_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit")
        )
        let spec = FormSpec(
            type: "au_becs_debit",
            async: false,
            fields: [.au_becs_bsb_number(.init(apiPath: ["v1": "au_becs_debit[bsb_number]"]))],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement.element) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("000-000")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.auBECSDebit?.bsbNumber)
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[bsb_number]"]
                as! String,
            "000000"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
    }

    func testMakeFormElement_AUBECSAccountNumber_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit")
        )
        let spec = FormSpec(
            type: "au_becs_debit",
            async: false,
            fields: [.au_becs_account_number(.init(apiPath: nil))],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement.element) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("000123456")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.auBECSDebit?.accountNumber, "000123456")
        XCTAssertNil(
            updatedParams?.paymentMethodParams.additionalAPIParameters[
                "au_becs_debit[account_number]"
            ]
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)

        // Using the params as previous customer input...
        let form_with_previous_input = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit"),
            previousCustomerInput: updatedParams
        ).makeFormElementFromSpec(spec: spec)
        // ...should result in a valid, filled out element
        XCTAssert(form_with_previous_input.validationState == .valid)
        let updatedParams_with_previous_input = form_with_previous_input.updateParams(params: .init(type: .dynamic("au_becs_debit")))
        XCTAssertEqual(updatedParams_with_previous_input?.paymentMethodParams.auBECSDebit?.accountNumber, "000123456")
    }

    func testMakeFormElement_AUBECSAccountNumber_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit")
        )
        let spec = FormSpec(
            type: "au_becs_debit",
            async: false,
            fields: [
                .au_becs_account_number(.init(apiPath: ["v1": "au_becs_debit[account_number]"])),
            ],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement.element) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("000123456")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.auBECSDebit?.accountNumber)
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters[
                "au_becs_debit[account_number]"
            ] as! String,
            "000123456"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)

        // Using the params as previous customer input...
        let form_with_previous_input = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit"),
            previousCustomerInput: updatedParams
        ).makeFormElementFromSpec(spec: spec)
        // ...should result in a valid, filled out element
        XCTAssert(form_with_previous_input.validationState == .valid)
        let updatedParams_with_previous_input = form_with_previous_input.updateParams(params: .init(type: .dynamic("au_becs_debit")))
        XCTAssertEqual(
            updatedParams_with_previous_input?.paymentMethodParams.additionalAPIParameters[
                "au_becs_debit[account_number]"
            ] as! String,
            "000123456"
        )
    }

    func testMakeFormElement_AUBECSAccountNumber() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit")
        )
        let accountNum = factory.makeAUBECSAccountNumber(apiPath: nil)
        accountNum.element.setText("000123456")

        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        let updatedParams = accountNum.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.auBECSDebit?.accountNumber, "000123456")
        XCTAssertNil(
            updatedParams?.paymentMethodParams.additionalAPIParameters[
                "au_becs_debit[account_number]"
            ]
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
    }

    func testMakeFormElement_AUBECSAccountNumber_withAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit")
        )
        let accountNum = factory.makeAUBECSAccountNumber(apiPath: "custom_path[account_number]")
        accountNum.element.setText("000123456")

        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        let updatedParams = accountNum.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.auBECSDebit?.accountNumber)
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters[
                "custom_path[account_number]"
            ] as! String,
            "000123456"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
    }

    func testMakeFormElement_BillingAddress_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("sofort")
        )
        let spec = FormSpec(
            type: "sofort",
            async: false,
            fields: [.country(.init(apiPath: nil, allowedCountryCodes: ["AT", "BE"]))],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("sofort"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.country, "AT")
        XCTAssert(updatedParams?.paymentMethodParams.additionalAPIParameters.isEmpty ?? false)
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sofort")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .sofort)
    }

    func testMakeFormElement_Country_DefinedAPIPath_forSofort() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("sofort")
        )
        let spec = FormSpec(
            type: "sofort",
            async: false,
            fields: [
                .country(
                    .init(apiPath: ["v1": "sofort[country]"], allowedCountryCodes: ["AT", "BE"])
                ),
            ],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("sofort"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.sofort?.country)
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters["sofort[country]"]
                as! String,
            "AT"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sofort")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .sofort)
    }

    func testMakeFormElement_Country() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("sofort")
        )
        let country = factory.makeCountry(countryCodes: ["AT", "BE"], apiPath: nil)
        (country as! PaymentMethodElementWrapper<DropdownFieldElement>).element.select(index: 1) // select a different index than the default of 0

        let params = IntentConfirmParams(type: .dynamic("sofort"))
        let updatedParams = country.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.country, "BE")
        XCTAssert(updatedParams?.paymentMethodParams.additionalAPIParameters.isEmpty ?? false)
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sofort")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .sofort)

        // Using the params as previous customer input...
        let country_with_previous_input = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("sofort"),
            previousCustomerInput: updatedParams
        ).makeCountry(countryCodes: ["AT", "BE"], apiPath: nil)
        // ...should result in a valid, filled out element
        XCTAssert(country_with_previous_input.validationState == .valid)
        let updatedParams_with_previous_input = country_with_previous_input.updateParams(params: .init(type: .dynamic("sofort")))
        XCTAssertEqual(updatedParams_with_previous_input?.paymentMethodParams.billingDetails?.address?.country, "BE")
    }

    func testMakeFormElement_Country_withAPIPath() {
        let configuration = PaymentSheet.Configuration()
        func makeCountry(previousCustomerInput: IntentConfirmParams?) -> PaymentMethodElement {
            let factory = PaymentSheetFormFactory(
                intent: .paymentIntent(STPFixtures.paymentIntent()),
                configuration: .paymentSheet(configuration),
                paymentMethod: .dynamic("sofort"),
                previousCustomerInput: previousCustomerInput
            )
            let country = factory.makeCountry(countryCodes: ["AT", "BE"], apiPath: "sofort[country]")
            return country
        }
        let country = makeCountry(previousCustomerInput: nil)
        (country as! PaymentMethodElementWrapper<DropdownFieldElement>).element.select(index: 1) // select a different index than the default of 0

        let params = IntentConfirmParams(type: .dynamic("sofort"))
        let updatedParams = country.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.sofort?.country)
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters["sofort[country]"]
                as! String,
            "BE"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sofort")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .sofort)

        // Using the params as previous customer input...
        let country_with_previous_input = makeCountry(previousCustomerInput: updatedParams)
        // ...should result in a valid, filled out element
        XCTAssert(country_with_previous_input.validationState == .valid)
        let updatedParams_with_previous_input = country_with_previous_input.updateParams(params: .init(type: .dynamic("sofort")))
        XCTAssertEqual(
            updatedParams_with_previous_input?.paymentMethodParams.additionalAPIParameters["sofort[country]"] as! String,
            "BE"
        )
    }

    func testMakeFormElement_Iban_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        func makeForm(previousCustomerInput: IntentConfirmParams?) -> PaymentMethodElementWrapper<FormElement> {
            let factory = PaymentSheetFormFactory(
                intent: .paymentIntent(STPFixtures.paymentIntent()),
                configuration: .paymentSheet(configuration),
                paymentMethod: .dynamic("sepa_debit"),
                previousCustomerInput: previousCustomerInput
            )
            let spec = FormSpec(
                type: "sepa_debit",
                async: false,
                fields: [.iban(.init(apiPath: nil))],
                selectorIcon: nil,
                nextActionSpec: nil
            )
            return factory.makeFormElementFromSpec(spec: spec)
        }
        let formElement = makeForm(previousCustomerInput: nil)
        let params = IntentConfirmParams(type: .dynamic("sepa_debit"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement.element) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("GB33BUKB20201555555555")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.sepaDebit?.iban, "GB33BUKB20201555555555")
        XCTAssert(updatedParams?.paymentMethodParams.additionalAPIParameters.isEmpty ?? false)
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sepa_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .SEPADebit)

        // Using the params as previous customer input...
        let form_with_previous_input = makeForm(previousCustomerInput: updatedParams)
        // ...should result in a valid, filled out element
        let updatedParams_with_previous_input = form_with_previous_input.updateParams(params: .init(type: .dynamic("sepa_debit")))
        XCTAssertEqual(updatedParams_with_previous_input?.paymentMethodParams.sepaDebit?.iban, "GB33BUKB20201555555555")
    }

    func testMakeFormElement_Iban_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        func makeForm(previousCustomerInput: IntentConfirmParams?) -> PaymentMethodElementWrapper<FormElement> {
            let factory = PaymentSheetFormFactory(
                intent: .paymentIntent(STPFixtures.paymentIntent()),
                configuration: .paymentSheet(configuration),
                paymentMethod: .dynamic("sepa_debit"),
                previousCustomerInput: previousCustomerInput
            )
            let spec = FormSpec(
                type: "sepa_debit",
                async: false,
                fields: [.iban(.init(apiPath: ["v1": "sepa_debit[iban]"]))],
                selectorIcon: nil,
                nextActionSpec: nil
            )
            return factory.makeFormElementFromSpec(spec: spec)
        }

        let formElement = makeForm(previousCustomerInput: nil)
        let params = IntentConfirmParams(type: .dynamic("sepa_debit"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement.element) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("GB33BUKB20201555555555")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.sepaDebit?.iban)
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters["sepa_debit[iban]"]
                as! String,
            "GB33BUKB20201555555555"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sepa_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .SEPADebit)

        // Using the params as previous customer input...
        let form_with_previous_input = makeForm(previousCustomerInput: updatedParams)
        // ...should result in a valid, filled out element
        let updatedParams_with_previous_input = form_with_previous_input.updateParams(params: .init(type: .dynamic("sepa_debit")))
        XCTAssertEqual(
            updatedParams_with_previous_input?.paymentMethodParams.additionalAPIParameters["sepa_debit[iban]"]
                as! String,
            "GB33BUKB20201555555555"
        )
    }

    func testMakeFormElement_Iban() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("sepa_debit")
        )
        let iban = factory.makeIban(apiPath: nil)
        iban.element.setText("GB33BUKB20201555555555")

        let params = IntentConfirmParams(type: .dynamic("sepa_debit"))
        let updatedParams = iban.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.sepaDebit?.iban, "GB33BUKB20201555555555")
        XCTAssert(updatedParams?.paymentMethodParams.additionalAPIParameters.isEmpty ?? false)
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sepa_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .SEPADebit)
    }

    func testMakeFormElement_Iban_withAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("sepa_debit")
        )
        let iban = factory.makeIban(apiPath: "sepa_debit[iban]")
        iban.element.setText("GB33BUKB20201555555555")

        let params = IntentConfirmParams(type: .dynamic("sepa_debit"))
        let updatedParams = iban.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.sepaDebit?.iban)
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.additionalAPIParameters["sepa_debit[iban]"]
                as! String,
            "GB33BUKB20201555555555"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sepa_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .SEPADebit)
    }

    func testMakeFormElement_email_with_unknownField() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("luxe_bucks")
        )
        let spec = FormSpec(
            type: "luxe_bucks",
            async: false,
            fields: [
                .unknown("some_unknownField1"),
                .email(.init(apiPath: nil)),
                .unknown("some_unknownField2"),
            ],
            selectorIcon: nil,
            nextActionSpec: nil
        )
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("luxe_bucks"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement.element) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("email@stripe.com")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.email, "email@stripe.com")
        XCTAssert(updatedParams?.paymentMethodParams.additionalAPIParameters.isEmpty ?? false)
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "luxe_bucks")
    }

    func testMakeFormElement_BillingAddress() {
        let addressSpecProvider = AddressSpecProvider()
        addressSpecProvider.addressSpecs = [
            "US": AddressSpec(
                format: "%N%n%O%n%A%n%C, %S %Z",
                require: "ACSZ",
                cityNameType: nil,
                stateNameType: .state,
                zip: "\\d{5}",
                zipNameType: .zip
            ),
        ]
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("au_becs_debit"),
            addressSpecProvider: addressSpecProvider
        )
        let accountNum = factory.makeBillingAddressSection(countries: nil)
        accountNum.element.line1?.setText("123 main")
        accountNum.element.line2?.setText("#501")
        accountNum.element.city?.setText("AnywhereTown")
        accountNum.element.state?.setRawData("California")
        accountNum.element.postalCode?.setText("55555")

        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        let updatedParams = accountNum.updateParams(params: params)

        XCTAssertEqual(
            updatedParams?.paymentMethodParams.billingDetails?.address?.line1,
            "123 main"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.line2, "#501")
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.country, "US")
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.billingDetails?.address?.city,
            "AnywhereTown"
        )
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.billingDetails?.address?.state,
            "California"
        )
        XCTAssertEqual(
            updatedParams?.paymentMethodParams.billingDetails?.address?.postalCode,
            "55555"
        )
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
    }

    func testMakeFormElement_AddressElementUsesDefaultCountries() {
        let addressSpecProvider = addressSpecProvider(countries: ["US", "FR"])
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mockPM"),
            addressSpecProvider: addressSpecProvider
        )
        let billingAddressSpec = FormSpec.BillingAddressSpec(allowedCountryCodes: nil)
        let spec = FormSpec(
            type: "mockPM",
            async: false,
            fields: [.billing_address(billingAddressSpec)],
            selectorIcon: nil,
            nextActionSpec: nil
        )

        let formElement = factory.makeFormElementFromSpec(spec: spec)
        guard let addressSectionElement = firstAddressSectionElement(formElement: formElement.element)
        else {
            XCTFail("failed to get address section element")
            return
        }

        XCTAssertEqual(addressSectionElement.countryCodes.count, 2)
        XCTAssertTrue(addressSectionElement.countryCodes.contains("US"))
        XCTAssertTrue(addressSectionElement.countryCodes.contains("FR"))
    }

    func testMakeFormElement_AddressElementUsesAllowedCountryCodes_FR() {
        let addressSpecProvider = addressSpecProvider(countries: ["US", "FR"])
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("mockPM"),
            addressSpecProvider: addressSpecProvider
        )
        let billingAddressSpec = FormSpec.BillingAddressSpec(allowedCountryCodes: ["FR"])
        let spec = FormSpec(
            type: "mockPM",
            async: false,
            fields: [.billing_address(billingAddressSpec)],
            selectorIcon: nil,
            nextActionSpec: nil
        )

        let formElement = factory.makeFormElementFromSpec(spec: spec)
        guard let addressSectionElement = firstAddressSectionElement(formElement: formElement.element)
        else {
            XCTFail("failed to get address section element")
            return
        }

        XCTAssertEqual(addressSectionElement.countryCodes.count, 1)
        XCTAssertTrue(addressSectionElement.countryCodes.contains("FR"))
    }

    func testNonCardsAndUSBankAccountsDontHaveSaveForFutureUseCheckbox() {
        let configuration = PaymentSheet.Configuration()
        let intent = Intent.paymentIntent(STPFixtures.paymentIntent())
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(
                format: "ACSZP",
                require: "AZ",
                cityNameType: .post_town,
                stateNameType: .state,
                zip: "",
                zipNameType: .pin
            ),
        ]
        let loadFormSpecs = expectation(description: "Load form specs")
        FormSpecProvider.shared.load { _ in
            loadFormSpecs.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        // No payment method should have a checkbox except for cards and US Bank Accounts
        for type in PaymentSheet.supportedPaymentMethods.filter({
            $0 != .card && $0 != .USBankAccount
        }) {
            let factory = PaymentSheetFormFactory(
                intent: intent,
                configuration: .paymentSheet(configuration),
                paymentMethod: PaymentSheet.PaymentMethodType(
                    from: STPPaymentMethod.string(from: type)!
                ),
                addressSpecProvider: specProvider
            )

            var form = factory.make()
            if let wrapper = form as? PaymentMethodElementWrapper<FormElement> {
                form = wrapper.element
            }

            guard let form = form as? FormElement else {
                XCTFail()
                return
            }
            if form.getAllUnwrappedSubElements()
                .compactMap({ $0 as? CheckboxElement })
                .contains(where: { $0.label.hasPrefix("Save") }) { // Hacky way to differentiate the save checkbox from other checkboxes
                XCTFail("\(type) contains a checkbox")
            }
        }
    }

    func testShowsCardCheckbox() {
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.card])
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: .paymentSheet(configuration),
            paymentMethod: .card
        )
        XCTAssertEqual(factory.saveMode, .userSelectable)
    }

    func testEPSDoesntHideCardCheckbox() {
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.card, .EPS])
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: .paymentSheet(configuration),
            paymentMethod: .card
        )
        XCTAssertEqual(factory.saveMode, .userSelectable)
    }

    func testBillingAddressSection() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "Line 2",
            postalCode: "94102",
            state: "CA"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        configuration.defaultBillingDetails.address = defaultAddress
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.card])
        // An address section with defaults...
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(
                format: "NOACSZ",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "",
                zipNameType: .zip
            ),
        ]
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: .paymentSheet(configuration),
            paymentMethod: .card,
            addressSpecProvider: specProvider
        )
        let addressSection = factory.makeBillingAddressSection(countries: nil)

        // ...should update params
        let intentConfirmParams = addressSection.updateParams(
            params: IntentConfirmParams(type: .card)
        )
        guard let billingDetails = intentConfirmParams?.paymentMethodParams.billingDetails?.address
        else {
            XCTFail()
            return
        }

        XCTAssertEqual(billingDetails.line1, defaultAddress.line1)
        XCTAssertEqual(billingDetails.line2, defaultAddress.line2)
        XCTAssertEqual(billingDetails.city, defaultAddress.city)
        XCTAssertEqual(billingDetails.postalCode, defaultAddress.postalCode)
        XCTAssertEqual(billingDetails.state, defaultAddress.state)
        XCTAssertEqual(billingDetails.country, defaultAddress.country)
    }

    func testPreferDefaultBillingDetailsOverShippingDetails() {
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        configuration.defaultBillingDetails.address = .init(line1: "Billing line 1")
        configuration.shippingDetails = {
            return .init(address: .init(country: "US", line1: "Shipping line 1"), name: "Name")
        }
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.card])
        // An address section with both default billing and default shipping...
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(
                format: "NOACSZ",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "",
                zipNameType: .zip
            ),
        ]
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: .paymentSheet(configuration),
            paymentMethod: .card,
            addressSpecProvider: specProvider
        )
        let addressSection = factory.makeBillingAddressSection(countries: nil)
        // ...sets the defaults to use billing and not shipping
        XCTAssertEqual(addressSection.element.line1?.text, "Billing line 1")
        // ...and doesn't show the shipping checkbox
        XCTAssertTrue(addressSection.element.sameAsCheckbox.view.isHidden)
    }

    func testApplyDefaults_Card_Applied() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "Line 2",
            postalCode: "94102",
            state: "CA"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        configuration.defaultBillingDetails.name = "Jane Doe"
        configuration.defaultBillingDetails.email = "foo@bar.com"
        configuration.defaultBillingDetails.phone = "+15555555555"
        configuration.defaultBillingDetails.address = defaultAddress
        configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod = true
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.card])
        // An address section with defaults...
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(
                format: "NOACSZ",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "",
                zipNameType: .zip
            ),
        ]
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: .paymentSheet(configuration),
            paymentMethod: .card,
            addressSpecProvider: specProvider
        )
        let cardForm = factory.makeCard()
        let params = cardForm.applyDefaults(params: IntentConfirmParams(type: .card))

        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.name, "Jane Doe")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.email, "foo@bar.com")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.phone, "+15555555555")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.line1, "510 Townsend St.")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.line2, "Line 2")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.city, "San Francisco")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.state, "CA")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.country, "US")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.postalCode, "94102")
    }

    func testApplyDefaults_Card_NotApplied() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "Line 2",
            postalCode: "94102",
            state: "CA"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        configuration.defaultBillingDetails.name = "Jane Doe"
        configuration.defaultBillingDetails.email = "foo@bar.com"
        configuration.defaultBillingDetails.phone = "+15555555555"
        configuration.defaultBillingDetails.address = defaultAddress
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.card])
        // An address section with defaults...
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(
                format: "NOACSZ",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "",
                zipNameType: .zip
            ),
        ]
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: .paymentSheet(configuration),
            paymentMethod: .card,
            addressSpecProvider: specProvider
        )
        let formElement = factory.make()
        let params = formElement.applyDefaults(params: IntentConfirmParams(type: .card))

        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.name)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.email)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.phone)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.address?.line1)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.address?.line2)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.address?.city)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.address?.state)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.address?.country)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.address?.postalCode)
    }

    func testApplyDefaults_LPM_Applied() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "Line 2",
            postalCode: "94102",
            state: "CA"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        configuration.defaultBillingDetails.name = "Jane Doe"
        configuration.defaultBillingDetails.email = "foo@bar.com"
        configuration.defaultBillingDetails.phone = "+15555555555"
        configuration.defaultBillingDetails.address = defaultAddress
        configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod = true
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.afterpayClearpay])
        // An address section with defaults...
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(
                format: "NOACSZ",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "",
                zipNameType: .zip
            ),
        ]

        let expectation = expectation(description: "FormSpecs loaded")
        FormSpecProvider.shared.load { _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)

        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("afterpay_clearpay"),
            addressSpecProvider: specProvider
        )
        let form = factory.make()
        let params = form.applyDefaults(params: IntentConfirmParams(type: .dynamic("afterpay_clearpay")))

        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.name, "Jane Doe")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.email, "foo@bar.com")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.phone, "+15555555555")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.line1, "510 Townsend St.")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.line2, "Line 2")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.city, "San Francisco")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.state, "CA")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.country, "US")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.postalCode, "94102")
    }

    func testApplyDefaults_LPM_NotApplied() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "Line 2",
            postalCode: "94102",
            state: "CA"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        configuration.defaultBillingDetails.name = "Jane Doe"
        configuration.defaultBillingDetails.email = "foo@bar.com"
        configuration.defaultBillingDetails.phone = "+15555555555"
        configuration.defaultBillingDetails.address = defaultAddress
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.afterpayClearpay])
        // An address section with defaults...
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(
                format: "NOACSZ",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "",
                zipNameType: .zip
            ),
        ]

        let expectation = expectation(description: "FormSpecs loaded")
        FormSpecProvider.shared.load { _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)

        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: .paymentSheet(configuration),
            paymentMethod: .dynamic("afterpay_clearpay"),
            addressSpecProvider: specProvider
        )
        let form = factory.make()
        let params = form.applyDefaults(params: IntentConfirmParams(type: .dynamic("afterpay_clearpay")))

        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.name)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.email)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.phone)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.address?.line1)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.address?.line2)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.address?.city)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.address?.state)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.address?.country)
        XCTAssertNil(params.paymentMethodParams.nonnil_billingDetails.address?.postalCode)
    }

    // MARK: - Previous Customer Input tests

    // Covers:
    // - Email
    // - Name
    // - Phone
    // - Billing address
    // - Card form
    // - Save checkbox
    func testAppliesPreviousCustomerInput_billing_details_and_card() {
        // Given default billing details...
        let defaultAddress = PaymentSheet.Address(
            city: "should not be used",
            country: "should not be used",
            line1: "should not be used",
            line2: "should not be used",
            postalCode: "should not be used",
            state: "should not be used"
        )
        var configuration = PaymentSheet.Configuration()
        // ...and a configuration that requires collection of all billing details...
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        configuration.defaultBillingDetails.name = "should not be used"
        configuration.defaultBillingDetails.email = "should not be usedm"
        configuration.defaultBillingDetails.phone = "should not be used"
        configuration.defaultBillingDetails.address = defaultAddress

        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)

        // ...and previous customer input billing details...
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"
        billingDetails.email = "foo@bar.com"
        billingDetails.phone = "5555555555"
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address?.line1 = "510 Townsend St."
        billingDetails.address?.line2 = "Line 2"
        billingDetails.address?.city = "San Francisco"
        billingDetails.address?.state = "CA"
        billingDetails.address?.country = "US"
        billingDetails.address?.postalCode = "94102"

        // ...and full card details...
        let cardValues = STPFixtures.paymentMethodCardParams()
        cardValues.expMonth = 3 // Choose a single digit month to exercise the code for padding with leading zeros
        let previousCustomerInput = IntentConfirmParams.init(
            params: .paramsWith(
                card: cardValues,
                billingDetails: billingDetails,
                metadata: nil),
            type: .card
        )

        // ...the card form...
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent(paymentMethodTypes: ["card"])),
            configuration: .paymentSheet(configuration),
            paymentMethod: .card,
            previousCustomerInput: previousCustomerInput
        )
        let cardForm = factory.make()

        // ...should be valid...
        XCTAssert(cardForm.validationState == .valid)
        // ...and its params should match the defaults above
        let params = cardForm.updateParams(params: IntentConfirmParams(type: .card))!
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.name, "Jane Doe")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.email, "foo@bar.com")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.phone, "+15555555555")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.line1, "510 Townsend St.")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.line2, "Line 2")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.city, "San Francisco")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.state, "CA")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.country, "US")
        XCTAssertEqual(params.paymentMethodParams.nonnil_billingDetails.address?.postalCode, "94102")

        XCTAssertEqual(params.paymentMethodParams.card?.number, cardValues.number)
        XCTAssertEqual(params.paymentMethodParams.card?.expMonth, cardValues.expMonth)
        XCTAssertEqual(params.paymentMethodParams.card?.expYear, cardValues.expYear)
        XCTAssertEqual(params.paymentMethodParams.card?.cvc, cardValues.cvc)
        // ...and the checkbox state should be enabled (the default)
        XCTAssertEqual(params.saveForFutureUseCheckboxState, .selected)
    }

    func testAppliesPreviousCustomerInput_checkbox() {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)

        func makeCardForm(isSettingUp: Bool, previousCustomerInput: IntentConfirmParams?) -> PaymentMethodElement {
            var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
            configuration.customer = .init(id: "id", ephemeralKeySecret: "ek")
            return PaymentSheetFormFactory(
                intent: isSettingUp ? .setupIntent(STPFixtures.setupIntent()) : .paymentIntent(STPFixtures.paymentIntent()),
                configuration: .paymentSheet(configuration),
                paymentMethod: .card,
                previousCustomerInput: previousCustomerInput
            ).make()
        }
        // A filled out card form in setup mode...
        let previousCustomerInput = IntentConfirmParams.init(
            params: .paramsWith(
                card: STPFixtures.paymentMethodCardParams(),
                billingDetails: STPFixtures.paymentMethodBillingDetails(),
                metadata: nil),
            type: .card
        )
        let cardForm_setup = makeCardForm(isSettingUp: true, previousCustomerInput: previousCustomerInput)
        // ...should have the checkbox hidden
        let cardForm_setup_params = cardForm_setup.updateParams(params: .init(type: .card))
        XCTAssertEqual(cardForm_setup_params?.saveForFutureUseCheckboxState, .hidden)

        // Making another card form for payment using the previous card form's input...
        let cardForm_payment = makeCardForm(isSettingUp: false, previousCustomerInput: cardForm_setup_params)
        // ...should have the checkbox selected (the default)
        let cardForm_payment_params = cardForm_payment.updateParams(params: .init(type: .card))
        XCTAssertEqual(cardForm_payment_params?.saveForFutureUseCheckboxState, .selected)

        // Deselecting the checkbox...
        let saveCheckbox = cardForm_payment.getAllUnwrappedSubElements().compactMap({ $0 as? CheckboxElement }).first(where: { $0.label.hasPrefix("Save") })
        saveCheckbox?.isSelected = false
        let cardForm_payment_params_checkbox_deselected = cardForm_payment.updateParams(params: .init(type: .card))
        XCTAssertEqual(cardForm_payment_params_checkbox_deselected?.saveForFutureUseCheckboxState, .deselected)
        // ...and making another card form...
        let cardForm_payment_2 = makeCardForm(isSettingUp: false, previousCustomerInput: cardForm_payment_params_checkbox_deselected)
        // ...should have the checkbox deselected, preserving the previous customer input
        let cardForm_payment_2_params = cardForm_payment_2.updateParams(params: .init(type: .card))
        XCTAssertEqual(cardForm_payment_2_params?.saveForFutureUseCheckboxState, .deselected)

    }

    func testAppliesPreviousCustomerInput_for_different_payment_method_type() {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)

        // ...Given previous customer input billing details...
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"
        billingDetails.email = "foo@bar.com"
        billingDetails.phone = "5555555555"
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address?.line1 = "510 Townsend St."
        billingDetails.address?.line2 = "Line 2"
        billingDetails.address?.city = "San Francisco"
        billingDetails.address?.state = "CA"
        billingDetails.address?.country = "US"
        billingDetails.address?.postalCode = "94102"

        // ...for Afterpay...
        let previousAfterpayCustomerInput = IntentConfirmParams.init(
            params: .paramsWith(afterpayClearpay: .init(), billingDetails: billingDetails, metadata: nil),
            type: .dynamic("afterpay_clearpay")
        )

        // ...the Afterpay form should be valid
        let afterpayFactory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent(paymentMethodTypes: ["afterpay_clearpay"])),
            configuration: .paymentSheet(PaymentSheet.Configuration._testValue_MostPermissive()),
            paymentMethod: .dynamic("afterpay_clearpay"),
            previousCustomerInput: previousAfterpayCustomerInput
        )
        let afterpayForm = afterpayFactory.make()
        XCTAssert(afterpayForm.validationState == .valid)

        // ...but if the customer previous input was for a card...
        let previousCardCustomerInput = IntentConfirmParams.init(
            params: .paramsWith(
                card: STPFixtures.paymentMethodCardParams(),
                billingDetails: billingDetails,
                metadata: nil),
            type: .card
        )
        // ...the Afterpay form should be blank and invalid, even though the previous input had full billing details
        let afterpayFormWithPreviousCardInput = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent(paymentMethodTypes: ["afterpay_clearpay"])),
            configuration: .paymentSheet(PaymentSheet.Configuration._testValue_MostPermissive()),
            paymentMethod: .dynamic("afterpay_clearpay"),
            previousCustomerInput: previousCardCustomerInput
        ).make()
        XCTAssert(afterpayFormWithPreviousCardInput.validationState != .valid)
        // ...and the address section shouldn't be populated with any defaults
        guard
            let afterpayForm = afterpayFormWithPreviousCardInput as? PaymentMethodElementWrapper<FormElement>,
            let addressSectionElement = afterpayForm.element.getAllUnwrappedSubElements().compactMap({ $0 as? AddressSectionElement }).first
        else {
            XCTFail("expected address section")
            return
        }
        let emptyAddressSectionElement = AddressSectionElement()
        XCTAssertEqual(addressSectionElement.addressDetails, emptyAddressSectionElement.addressDetails)
    }

    func testAppliesPreviousCustomerInput_klarna_country() {
        func makeKlarnaCountry(apiPath: String?, previousCustomerInput: IntentConfirmParams?) -> PaymentMethodElementWrapper<DropdownFieldElement> {
            let factory = PaymentSheetFormFactory(
                intent: .paymentIntent(STPFixtures.paymentIntent(paymentMethodTypes: ["klarna"], currency: "eur")),
                configuration: .paymentSheet(PaymentSheet.Configuration._testValue_MostPermissive()),
                paymentMethod: .dynamic("klarna"),
                previousCustomerInput: previousCustomerInput
            )
            return factory.makeKlarnaCountry(apiPath: apiPath) as! PaymentMethodElementWrapper<DropdownFieldElement>
        }
        let apiPathValues: [String?] = [nil, "billing_details[address][country]"] // Test the same thing with and without an api path
        apiPathValues.forEach { apiPath in
            // Given a klarna country...
            let klarnaCountry = makeKlarnaCountry(apiPath: apiPath, previousCustomerInput: nil)
            // ...with a selection *different* from the default of 0
            klarnaCountry.element.select(index: 1)
            // ...using its params as previous customer input to create a new klarna country...
            let previousCustomerInput = klarnaCountry.updateParams(params: IntentConfirmParams(type: .dynamic("klarna")))
            let klarnaCountry_with_previous_customer_input = makeKlarnaCountry(apiPath: apiPath, previousCustomerInput: previousCustomerInput)
            // ...should result in a valid element filled out with the previous customer input
            XCTAssertEqual(klarnaCountry_with_previous_customer_input.element.selectedIndex, 1)
            XCTAssertEqual(klarnaCountry_with_previous_customer_input.validationState, .valid)
        }
    }

    func testAppliesPreviousCustomerInput_for_mandate() {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)

        // Use PayPal as an example PM, since it is an empty form w/ a mandate iff PI+SFU or SI
        func makePaypalForm(isSettingUp: Bool, previousCustomerInput: IntentConfirmParams?) -> PaymentMethodElement {
            return PaymentSheetFormFactory(
                intent: .paymentIntent(STPFixtures.paymentIntent(paymentMethodTypes: ["paypal"], setupFutureUsage: isSettingUp ? .offSession : .none)),
                configuration: .paymentSheet(PaymentSheet.Configuration._testValue_MostPermissive()),
                paymentMethod: .dynamic("paypal"),
                previousCustomerInput: previousCustomerInput
            ).make()
        }

        // 1. nil -> valid Payment form
        // A paypal form for *payment* without previous customer input...
        let paypalForm_payment = makePaypalForm(isSettingUp: false, previousCustomerInput: nil)
        // ...should be valid - it requires no customer input.
        guard let paypalForm_payment_paymentOption = paypalForm_payment.updateParams(params: IntentConfirmParams(type: .dynamic("paypal"))) else {
            XCTFail("payment option should be non-nil")
            return
        }
        XCTAssertFalse(paypalForm_payment_paymentOption.didDisplayMandate)

        // 2. valid Payment form -> invalid Setup form
        // Creating a paypal form for *setup* using the old form as previous customer input...
        var paypalForm_setup = makePaypalForm(isSettingUp: true, previousCustomerInput: paypalForm_payment_paymentOption)
        // ...should not be valid...
        XCTAssertNil(paypalForm_setup.updateParams(params: IntentConfirmParams(type: .dynamic("paypal"))))
        // ...until the customer has seen the mandate...
        sendEventToSubviews(.viewDidAppear, from: paypalForm_setup.view)
        guard let paypalForm_setup_paymentOption = paypalForm_setup.updateParams(params: IntentConfirmParams(type: .dynamic("paypal"))) else {
            XCTFail("payment option should be non-nil")
            return
        }
        XCTAssertTrue(paypalForm_setup_paymentOption.didDisplayMandate)

        // 3. valid Setup form -> valid Setup form
        // Using the form's previous customer input to create another *setup* paypal form...
        paypalForm_setup = makePaypalForm(isSettingUp: true, previousCustomerInput: paypalForm_setup_paymentOption)
        // ...should be valid...
        guard let paypalForm_setup_paymentOption = paypalForm_setup.updateParams(params: IntentConfirmParams(type: .dynamic("paypal"))) else {
            XCTFail("payment option should be non-nil")
            return
        }
        XCTAssertTrue(paypalForm_setup_paymentOption.didDisplayMandate)
    }

    // MARK: - Helpers

    func addressSpecProvider(countries: [String]) -> AddressSpecProvider {
        let addressSpecProvider = AddressSpecProvider()
        let specs = [
            "US": AddressSpec(
                format: "%N%n%O%n%A%n%C, %S %Z",
                require: "ACSZ",
                cityNameType: nil,
                stateNameType: .state,
                zip: "\\d{5}",
                zipNameType: .zip
            ),
            "FR": AddressSpec(
                format: "%O%n%N%n%A%n%Z %C",
                require: "ACZ",
                cityNameType: nil,
                stateNameType: nil,
                zip: "\\d{2} ?\\d{3}",
                zipNameType: nil
            ),
        ]
        let filteredSpecs = specs.filter { countries.contains($0.key) }
        addressSpecProvider.addressSpecs = filteredSpecs
        return addressSpecProvider
    }

    private func firstWrappedTextFieldElement(
        formElement: FormElement
    ) -> PaymentMethodElementWrapper<TextFieldElement>? {
        guard let sectionElement = formElement.elements.first as? SectionElement,
            let wrappedElement = sectionElement.elements.first
                as? PaymentMethodElementWrapper<TextFieldElement>
        else {
            return nil
        }
        return wrappedElement
    }
    private func firstAddressSectionElement(formElement: FormElement) -> AddressSectionElement? {
        guard
            let wrapper = formElement.elements.first
                as? PaymentMethodElementWrapper<AddressSectionElement>
        else {
            return nil
        }
        return wrapper.element
    }
}

extension Element {
    /// A convenience method that overwrites the one defined in Element.swift that unwraps any Elements wrapped in `PaymentMethodElementWrapper`
    /// and returns all Elements underneath this Element, including this Element.
    public func getAllUnwrappedSubElements() -> [Element] {
        switch self {
        case let container as ContainerElement:
            return [container] + container.elements.flatMap { $0.getAllUnwrappedSubElements() }
        case let wrappedElement as PaymentMethodElementWrapper<FormElement>:
            return wrappedElement.element.getAllUnwrappedSubElements()
        case let wrappedElement as PaymentMethodElementWrapper<CheckboxElement>:
            return wrappedElement.element.getAllUnwrappedSubElements()
        case let wrappedElement as PaymentMethodElementWrapper<TextFieldElement>:
            return wrappedElement.element.getAllUnwrappedSubElements()
        case let wrappedElement as PaymentMethodElementWrapper<AddressSectionElement>:
            return wrappedElement.element.getAllUnwrappedSubElements()
        default:
            return [self]
        }
    }
}
