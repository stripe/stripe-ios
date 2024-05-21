//
//  FormSpecProviderTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

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
        XCTAssertEqual(eps.fields.count, 5)
        XCTAssertEqual(
            eps.fields.first,
            .name(FormSpec.NameFieldSpec(apiPath: ["v1": "billing_details[name]"], translationId: nil))
        )

        // ...and iDEAL has the correct dropdown spec
        guard let ideal = sut.formSpec(for: "ideal"),
              case .name = ideal.fields[0],
              case .selector(let selector) = ideal.fields[3]
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(selector.apiPath?["v1"], "ideal[bank]")
        XCTAssertEqual(selector.items.count, 13)
    }

    func testLoadJsonCanOverwriteLoadedSpecs() throws {
        let e1 = expectation(description: "Loads form specs file")
        let sut = FormSpecProvider()
        let paymentMethodType = "eps"
        sut.load { loaded in
            XCTAssertTrue(loaded)
            e1.fulfill()
        }
        wait(for: [e1], timeout: 2)
        let eps = try XCTUnwrap(sut.formSpec(for: paymentMethodType))
        XCTAssertEqual(eps.fields.count, 5)
        XCTAssertEqual(
            eps.fields.first,
            .name(FormSpec.NameFieldSpec(apiPath: ["v1": "billing_details[name]"], translationId: nil))
        )
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
        let formSpec = try! JSONSerialization.jsonObject(with: updatedSpecJson)

        let result = sut.loadFrom(formSpec)
        XCTAssert(result)

        let epsUpdated = try XCTUnwrap(sut.formSpec(for: paymentMethodType))
        XCTAssertEqual(epsUpdated.fields.count, 1)
        XCTAssertEqual(
            epsUpdated.fields.first,
            .name(
                FormSpec.NameFieldSpec(
                    apiPath: ["v1": "billing_details[someOtherValue]"],
                    translationId: nil
                )
            )
        )

        // If load is called again, ensure that on-disk specs do not override
        let e2 = expectation(description: "Loads form specs file, 2nd time")
        sut.load { loaded in
            XCTAssertTrue(loaded)
            e2.fulfill()
        }
        wait(for: [e2], timeout: 2)
        XCTAssertEqual(
            epsUpdated.fields.first,
            .name(
                FormSpec.NameFieldSpec(
                    apiPath: ["v1": "billing_details[someOtherValue]"],
                    translationId: nil
                )
            )
        )
    }

    func testLoadJsonFailsGracefully() throws {
        let e = expectation(description: "Loads form specs file")
        let sut = FormSpecProvider()
        let paymentMethodType = "eps"
        sut.load { loaded in
            XCTAssertTrue(loaded)
            e.fulfill()
        }
        waitForExpectations(timeout: 20, handler: nil)
        let eps = try XCTUnwrap(sut.formSpec(for: paymentMethodType))
        XCTAssertEqual(eps.fields.count, 5)
        XCTAssertEqual(
            eps.fields.first,
            .name(FormSpec.NameFieldSpec(apiPath: ["v1": "billing_details[name]"], translationId: nil))
        )
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
        let formSpec = try! JSONSerialization.jsonObject(with: updatedSpecJson)

        let result = sut.loadFrom(formSpec)
        XCTAssertFalse(result)
        let epsUpdated = try XCTUnwrap(sut.formSpec(for: paymentMethodType))
        XCTAssertEqual(epsUpdated.fields.count, 5)
        XCTAssertEqual(
            epsUpdated.fields.first,
            .name(FormSpec.NameFieldSpec(apiPath: ["v1": "billing_details[name]"], translationId: nil))
        )
    }

    func testLoadNotValidJsonFailsGracefully() throws {
        let e = expectation(description: "Loads form specs file")
        let sut = FormSpecProvider()
        let paymentMethodType = "eps"
        sut.load { loaded in
            XCTAssertTrue(loaded)
            e.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)

        let eps = try XCTUnwrap(sut.formSpec(for: paymentMethodType))
        XCTAssertEqual(eps.fields.count, 5)
        XCTAssertEqual(
            eps.fields.first,
            .name(FormSpec.NameFieldSpec(apiPath: ["v1": "billing_details[name]"], translationId: nil))
        )

        let updatedSpecJson =
            """
            NOT VALID JSON
            """.data(using: .utf8)!

        let result = sut.loadFrom(updatedSpecJson)
        XCTAssertFalse(result)
        let epsUpdated = try XCTUnwrap(sut.formSpec(for: paymentMethodType))
        XCTAssertEqual(epsUpdated.fields.count, 5)
        XCTAssertEqual(
            epsUpdated.fields.first,
            .name(FormSpec.NameFieldSpec(apiPath: ["v1": "billing_details[name]"], translationId: nil))
        )
    }

    func testLoadJsonDoesOverwrites() throws {
        let e = expectation(description: "Loads form specs file")
        let sut = FormSpecProvider()
        let paymentMethodType = "eps"
        sut.load { loaded in
            XCTAssertTrue(loaded)
            e.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
        let eps = try XCTUnwrap(sut.formSpec(for: paymentMethodType))
        XCTAssertEqual(eps.fields.count, 5)
        XCTAssertEqual(
            eps.fields.first,
            .name(FormSpec.NameFieldSpec(apiPath: ["v1": "billing_details[name]"], translationId: nil))
        )

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
                ],
                "next_action_spec": {
                    "confirm_response_status_specs": {
                        "requires_action": {
                            "type": "redirect_to_url"
                        }
                    },
                    "post_confirm_handling_pi_status_specs": {
                        "succeeded": {
                            "type": "finished"
                        },
                        "requires_action": {
                            "type": "finished"
                        }
                    }
                }
            }]
            """.data(using: .utf8)!
        let formSpec = try! JSONSerialization.jsonObject(with: updatedSpecJson)

        let result = sut.loadFrom(formSpec)
        XCTAssert(result)

        // Validate ability to override LPM behavior of next actions
        let epsUpdated = try XCTUnwrap(sut.formSpec(for: paymentMethodType))
        XCTAssertEqual(epsUpdated.fields.count, 1)
        XCTAssertEqual(
            epsUpdated.fields.first,
            .name(
                FormSpec.NameFieldSpec(
                    apiPath: ["v1": "billing_details[someOtherValue]"],
                    translationId: nil
                )
            )
        )
    }
}
