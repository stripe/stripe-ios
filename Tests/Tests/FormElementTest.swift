//
//  FormElementTest.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

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

class FormElementTest: XCTestCase {
    func testUpdatesParams() {
        // A FormElement containing an element should update the params before its children
        let a = MockElement() { params in
            // paymentMethodParams.sofort is an example of a sub-object that should be non-nil by the time this element sees it
            XCTAssertNotNil(params.paymentMethodParams.sofort)
            params.paymentMethodParams.sofort?.country = "GB"
            return params
        }
        
        let form = FormElement(elements: [a]) { params in
            params.paymentMethodParams.type = .sofort
            params.paymentMethodParams.sofort = STPPaymentMethodSofortParams()
            return params
        }
        
        let params = form.updateParams(params: IntentConfirmParams(type: .sofort))
        XCTAssertEqual(params?.paymentMethodParams.sofort?.country, "GB")
        XCTAssertEqual(params?.paymentMethodParams.type, .sofort)
    }
}
