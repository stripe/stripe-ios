//
//  FormSpecProviderTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import Stripe
@_spi(STP) @testable import StripeUICore

class FormSpecProviderTest: XCTestCase {
    func testLoadsJSON() throws {
        let e = expectation(description: "Loads form specs file")
        let sut = FormSpecProvider()
        sut.load { loaded in
            XCTAssertTrue(loaded)
            e.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
        
        guard let eps = sut.formSpec(for: "eps") else {
            XCTFail()
            return
        }
        XCTAssertEqual(eps.fields.count, 2)
        XCTAssertEqual(eps.fields.first, .name(FormSpec.NameFieldSpec(apiPath:nil, translationId: nil)))

        // ...and iDEAL has the correct dropdown spec
        guard let ideal = sut.formSpec(for: "ideal"),
              case .name = ideal.fields[0],
              case let .selector(selector) = ideal.fields[1] else {
                  XCTFail()
            return
        }
        XCTAssertEqual(selector.apiPath?["v1"], "ideal[bank]")
        XCTAssertEqual(selector.items.count, 13)
    }

    func testLoadJsonCanOverwriteLoadedSpecs() throws {
        let e = expectation(description: "Loads form specs file")
        let sut = FormSpecProvider()
        let paymentMethodType = "eps"
        sut.load { loaded in
            XCTAssertTrue(loaded)
            e.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
        guard let eps = sut.formSpec(for: paymentMethodType) else {
            XCTFail()
            return
        }
        XCTAssertEqual(eps.fields.count, 2)
        XCTAssertEqual(eps.fields.first, .name(FormSpec.NameFieldSpec(apiPath:nil, translationId: nil)))
        let updatedSpecJson =
        """
        [{
            "type": "eps",
            "async": false,
            "fields": [
                {
                    "type": "name",
                    "api_path": {
                        "v1": "billing_details[someOtherValue]"
                    }
                }
            ]
        }]
        """.data(using: .utf8)!
        let formSpec = try! JSONSerialization.jsonObject(with: updatedSpecJson) as! [NSDictionary]
        sut.load(from: formSpec)
        guard let epsUpdated = sut.formSpec(for: paymentMethodType) else {
            XCTFail()
            return
        }

        XCTAssertEqual(epsUpdated.fields.count, 1)
        XCTAssertEqual(epsUpdated.fields.first, .name(FormSpec.NameFieldSpec(apiPath:["v1":"billing_details[someOtherValue]"], translationId: nil)))
    }

    func testLoadJsonFailsGracefully() throws {
        let e = expectation(description: "Loads form specs file")
        let sut = FormSpecProvider()
        let paymentMethodType = "eps"
        sut.load { loaded in
            XCTAssertTrue(loaded)
            e.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
        guard let eps = sut.formSpec(for: paymentMethodType) else {
            XCTFail()
            return
        }
        XCTAssertEqual(eps.fields.count, 2)
        XCTAssertEqual(eps.fields.first, .name(FormSpec.NameFieldSpec(apiPath:nil, translationId: nil)))
        let updatedSpecJson =
        """
        [{
            "INVALID_type": "eps",
            "async": false,
            "fields": [
                {
                    "type": "name",
                    "api_path": {
                        "v1": "billing_details[someOtherValue]"
                    }
                }
            ]
        }]
        """.data(using: .utf8)!
        let formSpec = try! JSONSerialization.jsonObject(with: updatedSpecJson) as! [NSDictionary]
        sut.load(from: formSpec)
        guard let epsUpdated = sut.formSpec(for: paymentMethodType) else {
            XCTFail()
            return
        }
        XCTAssertEqual(epsUpdated.fields.count, 2)
        XCTAssertEqual(epsUpdated.fields.first, .name(FormSpec.NameFieldSpec(apiPath:nil, translationId: nil)))
    }
}
