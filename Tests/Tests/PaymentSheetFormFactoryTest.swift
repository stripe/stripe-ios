//
//  PaymentSheetFormFactoryTest.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import Stripe
@_spi(STP) @testable import StripeUICore

class MockElement: Element {
    var paramsUpdater: (IntentConfirmParams) -> IntentConfirmParams?
    
    init(paramsUpdater: @escaping (IntentConfirmParams) -> IntentConfirmParams?) {
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
            configuration: configuration,
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
            configuration: configuration,
            paymentMethod: .dynamic("eps")
        )

        guard let spec = factory.specFromJSONProvider(provider: provider) else {
            XCTFail("Unable to load EPS Spec")
            return
        }

        XCTAssertEqual(spec.fields.count, 2)
        XCTAssertEqual(spec.fields.first, .name(.init(apiPath: nil, translationId: nil)))
        XCTAssertEqual(spec.type, "eps")
    }

    func testNameOverrideApiPathBySpec() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("mock_payment_method")
        )
        let name = factory.makeName(apiPath: "custom_location[name]")
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = name.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.name)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"] as! String, "someName")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)
    }

    func testNameValueWrittenToDefaultLocation() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("mock_payment_method")
        )
        let name = factory.makeName()
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = name.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.name, "someName")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"])
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)
    }

    func testNameValueWrittenToLocationDefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("mock_payment_method")
        )
        let nameSpec = FormSpec.NameFieldSpec(apiPath: ["v1": "custom_location[name]"], translationId: nil)
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.name(nameSpec)], nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.name)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"] as! String, "someName")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)
    }

    func testNameValueWrittenToLocationUndefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("mock_payment_method")
        )
        let nameSpec = FormSpec.NameFieldSpec(apiPath: nil, translationId: nil)
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.name(nameSpec)], nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"])
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.name, "someName")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)
    }

    func testEmailOverrideApiPathBySpec() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("mock_payment_method")
        )
        let email = factory.makeEmail(apiPath: "custom_location[email]")
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = email.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"] as! String, "email@stripe.com")
        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.email)
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)
    }

    func testEmailValueWrittenToDefaultLocation() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("mock_payment_method")
        )
        let email = factory.makeEmail()
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = email.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.email, "email@stripe.com")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"])
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)
    }

    func testEmailValueWrittenToLocationDefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("mock_payment_method")
        )
        let emailSpec = FormSpec.BaseFieldSpec(apiPath: ["v1": "custom_location[email]"])
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.email(emailSpec)], nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.email)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"] as! String, "email@stripe.com")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)
    }

    func testEmailValueWrittenToLocationUndefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("mock_payment_method")
        )

        let emailSpec = FormSpec.BaseFieldSpec(apiPath: nil)
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.email(emailSpec)], nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("mock_payment_method"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.email, "email@stripe.com")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"])
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "mock_payment_method")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .unknown)
    }

    func testMakeFormElement_dropdown() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("sepa_debit")
        )
        let selectorSpec = FormSpec.SelectorSpec(translationId: .eps_bank,
                                                 items: [.init(displayText: "d1", apiValue: "123"),
                                                         .init(displayText: "d2", apiValue: "456")],
                                                 apiPath: ["v1": "custom_location[selector]"])
        let spec = FormSpec(type: "sepa_debit", async: false, fields: [.selector(selectorSpec)], nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("sepa_debit"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[selector]"] as! String, "123")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sepa_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .SEPADebit)
    }

    func testMakeFormElement_KlarnaCountry_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("klarna")
        )
        let spec = FormSpec(type: "klarna",
                            async: false,
                            fields: [.klarna_country(.init(apiPath: nil))],
                            nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("klarna"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.country, "US")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["billing_details[address][country]"])
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "klarna")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .klarna)
    }

    func testMakeFormElement_KlarnaCountry_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("klarna")
        )
        let spec = FormSpec(type: "klarna",
                            async: false,
                            fields: [.klarna_country(.init(apiPath:["v1":"billing_details[address][country]"]))],
                            nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("klarna"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.address?.country)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["billing_details[address][country]"] as! String, "US")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "klarna")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .klarna)
    }

    func testMakeFormElement_BSBNumber() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("au_becs_debit")
        )
        let bsb = factory.makeBSB(apiPath: nil)
        bsb.element.setText("000-000")

        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        let updatedParams = bsb.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.auBECSDebit?.bsbNumber, "000000")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[bsb_number]"])
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
    }

    func testMakeFormElement_BSBNumber_withAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("au_becs_debit")
        )
        let bsb = factory.makeBSB(apiPath: "custom_path[bsb_number]")
        bsb.element.setText("000-000")

        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        let updatedParams = bsb.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.auBECSDebit?.bsbNumber)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_path[bsb_number]"] as! String, "000000")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
    }

    func testMakeFormElement_BSBNumber_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("au_becs_debit")
        )
        let spec = FormSpec(type: "au_becs_debit",
                            async: false,
                            fields: [.au_becs_bsb_number(.init(apiPath: nil))],
                            nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("000-000")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.auBECSDebit?.bsbNumber, "000000")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[bsb_number]"])
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
    }

    func testMakeFormElement_BSBNumber_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("au_becs_debit")
        )
        let spec = FormSpec(type: "au_becs_debit",
                            async: false,
                            fields: [.au_becs_bsb_number(.init(apiPath: ["v1":"au_becs_debit[bsb_number]"]))],
                            nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("000-000")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.auBECSDebit?.bsbNumber)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[bsb_number]"] as! String, "000000")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
    }

    func testMakeFormElement_AUBECSAccountNumber_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("au_becs_debit")
        )
        let spec = FormSpec(type: "au_becs_debit",
                            async: false,
                            fields: [.au_becs_account_number(.init(apiPath: nil))],
                            nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("000123456")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.auBECSDebit?.accountNumber, "000123456")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[account_number]"])
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
    }

    func testMakeFormElement_AUBECSAccountNumber_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("au_becs_debit")
        )
        let spec = FormSpec(type: "au_becs_debit",
                            async: false,
                            fields: [.au_becs_account_number(.init(apiPath: ["v1":"au_becs_debit[account_number]"]))],
                            nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("000123456")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.auBECSDebit?.accountNumber)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[account_number]"] as! String, "000123456")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
    }

    func testMakeFormElement_AUBECSAccountNumber() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("au_becs_debit")
        )
        let accountNum = factory.makeAUBECSAccountNumber(apiPath: nil)
        accountNum.element.setText("000123456")

        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        let updatedParams = accountNum.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.auBECSDebit?.accountNumber, "000123456")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[account_number]"])
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
    }

    func testMakeFormElement_AUBECSAccountNumber_withAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("au_becs_debit")
        )
        let accountNum = factory.makeAUBECSAccountNumber(apiPath: "custom_path[account_number]")
        accountNum.element.setText("000123456")

        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        let updatedParams = accountNum.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.auBECSDebit?.accountNumber)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_path[account_number]"] as! String, "000123456")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
    }

    func testMakeFormElement_BillingAddress_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("sofort")
        )
        let spec = FormSpec(type: "sofort",
                            async: false,
                            fields: [.country(.init(apiPath: nil, allowedCountryCodes: ["AT", "BE"]))],
                            nextActionSpec: nil)
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
            configuration: configuration,
            paymentMethod: .dynamic("sofort")
        )
        let spec = FormSpec(type: "sofort",
                            async: false,
                            fields: [.country(.init(apiPath: ["v1":"sofort[country]"], allowedCountryCodes: ["AT", "BE"]))],
                            nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("sofort"))

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.sofort?.country)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["sofort[country]"] as! String, "AT")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sofort")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .sofort)
    }

    func testMakeFormElement_Country() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("sofort")
        )
        let country = factory.makeCountry(countryCodes: ["AT", "BE"], apiPath: nil)

        let params = IntentConfirmParams(type: .dynamic("sofort"))
        let updatedParams = country.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.country, "AT")
        XCTAssert(updatedParams?.paymentMethodParams.additionalAPIParameters.isEmpty ?? false)
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sofort")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .sofort)
    }

    func testMakeFormElement_Country_withAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("sofort")
        )
        let country = factory.makeCountry(countryCodes: ["AT", "BE"], apiPath: "sofort[country]")

        let params = IntentConfirmParams(type: .dynamic("sofort"))
        let updatedParams = country.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.sofort?.country)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["sofort[country]"] as! String, "AT")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sofort")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .sofort)
    }

    func testMakeFormElement_Iban_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("sepa_debit")
        )
        let spec = FormSpec(type: "sepa_debit",
                            async: false,
                            fields: [.iban(.init(apiPath: nil))],
                            nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("sepa_debit"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("GB33BUKB20201555555555")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.sepaDebit?.iban, "GB33BUKB20201555555555")
        XCTAssert(updatedParams?.paymentMethodParams.additionalAPIParameters.isEmpty ?? false)
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sepa_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .SEPADebit)
    }

    func testMakeFormElement_Iban_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("sepa_debit")
        )
        let spec = FormSpec(type: "sepa_debit",
                            async: false,
                            fields: [.iban(.init(apiPath: ["v1": "sepa_debit[iban]"]))],
                            nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("sepa_debit"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("GB33BUKB20201555555555")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.sepaDebit?.iban)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["sepa_debit[iban]"] as! String, "GB33BUKB20201555555555")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sepa_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .SEPADebit)
    }

    func testMakeFormElement_Iban() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
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
            configuration: configuration,
            paymentMethod: .dynamic("sepa_debit")
        )
        let iban = factory.makeIban(apiPath: "sepa_debit[iban]")
        iban.element.setText("GB33BUKB20201555555555")

        let params = IntentConfirmParams(type: .dynamic("sepa_debit"))
        let updatedParams = iban.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.sepaDebit?.iban)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["sepa_debit[iban]"] as! String, "GB33BUKB20201555555555")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "sepa_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .SEPADebit)
    }

    func testMakeFormElement_email_with_unknownField() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("luxe_bucks")
        )
        let spec = FormSpec(type: "luxe_bucks",
                            async: false,
                            fields: [
                                .unknown("some_unknownField1"),
                                .email(.init(apiPath: nil)),
                                .unknown("some_unknownField2"),
                            ],
                            nextActionSpec: nil)
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .dynamic("luxe_bucks"))
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement) else {
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
        addressSpecProvider.addressSpecs = ["US": AddressSpec(format: "%N%n%O%n%A%n%C, %S %Z",
                                                              require: "ACSZ",
                                                              cityNameType: nil,
                                                              stateNameType: .state,
                                                              zip: "\\d{5}",
                                                              zipNameType: .zip)]
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("au_becs_debit"),
            addressSpecProvider: addressSpecProvider
        )
        let accountNum = factory.makeBillingAddressSection(countries: nil)
        accountNum.element.line1?.setText("123 main")
        accountNum.element.line2?.setText("#501")
        accountNum.element.city?.setText("AnywhereTown")
        accountNum.element.state?.setText("California")
        accountNum.element.postalCode?.setText("55555")

        let params = IntentConfirmParams(type: .dynamic("au_becs_debit"))
        let updatedParams = accountNum.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.line1, "123 main")
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.line2, "#501")
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.country, "US")
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.city, "AnywhereTown")
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.state, "California")
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.postalCode, "55555")
        XCTAssertEqual(updatedParams?.paymentMethodParams.rawTypeString, "au_becs_debit")
        XCTAssertEqual(updatedParams?.paymentMethodParams.type, .AUBECSDebit)
    }

    func testMakeFormElement_AddressElementUsesDefaultCountries() {
        let addressSpecProvider = addressSpecProvider(countries: ["US", "FR"])
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .dynamic("mockPM"),
            addressSpecProvider: addressSpecProvider
        )
        let billingAddressSpec = FormSpec.BillingAddressSpec(allowedCountryCodes: nil)
        let spec = FormSpec(type: "mockPM", async: false, fields: [.billing_address(billingAddressSpec)], nextActionSpec: nil)

        let formElement = factory.makeFormElementFromSpec(spec: spec)
        guard let addressSectionElement = firstAddressSectionElement(formElement: formElement) else {
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
            configuration: configuration,
            paymentMethod: .dynamic("mockPM"),
            addressSpecProvider: addressSpecProvider
        )
        let billingAddressSpec = FormSpec.BillingAddressSpec(allowedCountryCodes: ["FR"])
        let spec = FormSpec(type: "mockPM", async: false, fields: [.billing_address(billingAddressSpec)], nextActionSpec: nil)

        let formElement = factory.makeFormElementFromSpec(spec: spec)
        guard let addressSectionElement = firstAddressSectionElement(formElement: formElement) else {
            XCTFail("failed to get address section element")
            return
        }

        XCTAssertEqual(addressSectionElement.countryCodes.count, 1)
        XCTAssertTrue(addressSectionElement.countryCodes.contains("FR"))
    }

    func testNonCardsDontHaveCheckbox() {
        let configuration = PaymentSheet.Configuration()
        let intent = Intent.paymentIntent(STPFixtures.paymentIntent())
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
        ]
        let loadFormSpecs = expectation(description: "Load form specs")
        FormSpecProvider.shared.load { _ in
            loadFormSpecs.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        for type in PaymentSheet.supportedPaymentMethods.filter({ $0 != .card && $0 != .USBankAccount }) {
            let factory = PaymentSheetFormFactory(
                intent: intent,
                configuration: configuration,
                paymentMethod: PaymentSheet.PaymentMethodType(from: STPPaymentMethod.string(from: type)!),
                addressSpecProvider: specProvider
            )
            
            guard let form = factory.make() as? FormElement else {
                XCTFail()
                return
            }
            XCTAssertFalse(form.getAllSubElements().contains {
                $0 is PaymentMethodElementWrapper<CheckboxElement> || $0 is CheckboxElement
            })
        }
    }

    func testShowsCardCheckbox() {
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.card])
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: configuration,
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
            configuration: configuration,
            paymentMethod: .card
        )
        XCTAssertEqual(factory.saveMode, .userSelectable)
    }

    func testBillingAddressSection() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco", country: "US", line1: "510 Townsend St.", line2: "Line 2", postalCode: "94102", state: "CA"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        configuration.defaultBillingDetails.address = defaultAddress
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.card])
        // An address section with defaults...
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "NOACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .state, zip: "", zipNameType: .zip),
        ]
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: configuration,
            paymentMethod: .card,
            addressSpecProvider: specProvider
        )
        let addressSection = factory.makeBillingAddressSection(countries: nil)

        // ...should update params
        let intentConfirmParams = addressSection.updateParams(params: IntentConfirmParams(type: .card))
        guard let billingDetails = intentConfirmParams?.paymentMethodParams.billingDetails?.address else {
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
        configuration.shippingDetails = { return .init(address: .init(country: "US", line1: "Shipping line 1"), name: "Name") }
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.card])
        // An address section with both default billing and default shipping...
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "NOACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .state, zip: "", zipNameType: .zip),
        ]
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: configuration,
            paymentMethod: .card,
            addressSpecProvider: specProvider
        )
        let addressSection = factory.makeBillingAddressSection(countries: nil)
        // ...sets the defaults to use billing and not shipping
        XCTAssertEqual(addressSection.element.line1?.text, "Billing line 1")
        // ...and doesn't show the shipping checkbox
        XCTAssertTrue(addressSection.element.sameAsCheckbox.view.isHidden)
    }
    
    func addressSpecProvider(countries: [String]) -> AddressSpecProvider {
        let addressSpecProvider = AddressSpecProvider()
        let specs = ["US": AddressSpec(format: "%N%n%O%n%A%n%C, %S %Z",
                                       require: "ACSZ",
                                       cityNameType: nil,
                                       stateNameType: .state,
                                       zip: "\\d{5}",
                                       zipNameType: .zip),
                     "FR": AddressSpec(format: "%O%n%N%n%A%n%Z %C",
                                       require: "ACZ",
                                       cityNameType: nil,
                                       stateNameType: nil,
                                       zip: "\\d{2} ?\\d{3}",
                                       zipNameType: nil)]
        let filteredSpecs = specs.filter {countries.contains($0.key)}
        addressSpecProvider.addressSpecs = filteredSpecs
        return addressSpecProvider
    }

    private func firstWrappedTextFieldElement(formElement: FormElement) -> PaymentMethodElementWrapper<TextFieldElement>? {
        guard let sectionElement = formElement.elements.first as? SectionElement,
              let wrappedElement = sectionElement.elements.first as? PaymentMethodElementWrapper<TextFieldElement> else {
                  return nil
              }
        return wrappedElement
    }
    private func firstAddressSectionElement(formElement: FormElement) -> AddressSectionElement? {
        guard let wrapper = formElement.elements.first as? PaymentMethodElementWrapper<AddressSectionElement> else {
            return nil
        }
        return wrapper.element
    }
}
