//
//  PaymentSheetFormFactoryTest.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe
@_spi(STP) import Stripe

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
        let name = factory.makeName()
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
}
