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
            paymentMethod: .SEPADebit
        )
        let name = factory.makeFullName()
        let email = factory.makeEmail()
        let checkbox = factory.makeSaveCheckbox { _ in }
        
        let form = FormElement(elements: [name, email, checkbox])
        let params = form.updateParams(params: IntentConfirmParams(type: .SEPADebit))

        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.name, "Name")
        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.email, "email@stripe.com")
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
            paymentMethod: .EPS
        )

        guard let spec = factory.specFromJSONProvider(provider: provider) else {
            XCTFail("Unable to load EPS Spec")
            return
        }

        XCTAssertEqual(spec.fields.count, 2)
        XCTAssertEqual(spec.fields.first, .name(.init(apiPath: ["v1": "billing_details[name]"])))
    }

    func testNameOverrideApiPathBySpec() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let name = factory.makeFullName(apiPath: "custom_location[name]")
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = name.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.name)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"] as! String, "someName")
    }

    func testNameValueWrittenToDefaultLocation() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let name = factory.makeFullName()
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = name.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.name, "someName")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"])
    }

    func testNameValueWrittenToLocationDefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let nameSpec = FormSpec.BaseFieldSpec(apiPath: ["v1": "custom_location[name]"])
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.name(nameSpec)])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.name)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"] as! String, "someName")
    }

    func testNameValueWrittenToLocationUndefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let nameSpec = FormSpec.BaseFieldSpec(apiPath: nil)
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.name(nameSpec)])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"])
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.name, "someName")
    }

    func testEmailOverrideApiPathBySpec() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let email = factory.makeEmail(apiPath: "custom_location[email]")
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = email.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"] as! String, "email@stripe.com")
        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.email)
    }

    func testEmailValueWrittenToDefaultLocation() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let email = factory.makeEmail()
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = email.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.email, "email@stripe.com")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"])
    }

    func testEmailValueWrittenToLocationDefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let emailSpec = FormSpec.BaseFieldSpec(apiPath: ["v1": "custom_location[email]"])
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.email(emailSpec)])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.email)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"] as! String, "email@stripe.com")
    }

    func testEmailValueWrittenToLocationUndefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )

        let emailSpec = FormSpec.BaseFieldSpec(apiPath: nil)
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.email(emailSpec)])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.email, "email@stripe.com")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"])
    }
    
    func testMakeFormElement_dropdown() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .SEPADebit
        )
        let selectorSpec = FormSpec.SelectorSpec(label: .eps_bank,
                                                 items: [.init(displayText: "d1", apiValue: "123"),
                                                         .init(displayText: "d2", apiValue: "456")],
                                                 apiPath: ["v1": "custom_location[selector]"])
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.selector(selectorSpec)])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[selector]"] as! String, "123")
    }

    func testMakeFormElement_KlarnaCountry_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .klarna
        )
        let spec = FormSpec(type: "mock_klarna",
                            async: false,
                            fields: [.klarna_country(.init(apiPath: nil))])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.country, "US")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["billing_details[address][country]"])
    }

    func testMakeFormElement_KlarnaCountry_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .klarna
        )
        let spec = FormSpec(type: "mock_klarna",
                            async: false,
                            fields: [.klarna_country(.init(apiPath:["v1":"billing_details[address][country]"]))])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.address?.country)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["billing_details[address][country]"] as! String, "US")
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
                paymentMethod: type,
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
        let addressSection = factory.makeBillingAddressSection()

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
}
