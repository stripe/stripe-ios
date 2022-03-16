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
        for type in PaymentSheet.supportedPaymentMethods.filter({ $0 != .card }) {
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
                $0 is PaymentMethodElementWrapper<SaveCheckboxElement> || $0 is SaveCheckboxElement
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
