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
        XCTAssertEqual(selector.items.count, 11)
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
        guard
            case .redirect_to_url = eps.nextActionSpec?.confirmResponseStatusSpecs[
                "requires_action"
            ]?.type,
            case .finished = eps.nextActionSpec?.postConfirmHandlingPiStatusSpecs?["succeeded"]?
                .type,
            case .canceled = eps.nextActionSpec?.postConfirmHandlingPiStatusSpecs?[
                "requires_action"
            ]?.type
        else {
            XCTFail()
            return
        }

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
        guard
            case .redirect_to_url = epsUpdated.nextActionSpec?.confirmResponseStatusSpecs[
                "requires_action"
            ]?.type,
            case .finished = epsUpdated.nextActionSpec?.postConfirmHandlingPiStatusSpecs?[
                "succeeded"
            ]?.type,
            case .finished = epsUpdated.nextActionSpec?.postConfirmHandlingPiStatusSpecs?[
                "requires_action"
            ]?.type
        else {
            XCTFail()
            return
        }
    }

    func testLoadJsonDoesOverwritesWithoutNextActionSpec() throws {
        let e = expectation(description: "Loads form specs file")
        let sut = FormSpecProvider()
        let paymentMethodType = "affirm"
        sut.load { loaded in
            XCTAssertTrue(loaded)
            e.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
        let affirm = try XCTUnwrap(sut.formSpec(for: paymentMethodType))
        XCTAssertEqual(affirm.fields.count, 1)
        XCTAssertEqual(affirm.fields.first, .affirm_header)
        guard
            case .redirect_to_url = affirm.nextActionSpec?.confirmResponseStatusSpecs[
                "requires_action"
            ]?.type,
            case .finished = affirm.nextActionSpec?.postConfirmHandlingPiStatusSpecs?["succeeded"]?
                .type,
            case .canceled = affirm.nextActionSpec?.postConfirmHandlingPiStatusSpecs?[
                "requires_action"
            ]?.type
        else {
            XCTFail()
            return
        }

        let updatedSpecJson =
            """
            [{
                "type": "affirm",
                "async": false,
                "fields": [
                    {
                        "type": "name"
                    }
                ]
            }]
            """.data(using: .utf8)!
        let formSpec = try! JSONSerialization.jsonObject(with: updatedSpecJson) as! [NSDictionary]

        let result = sut.loadFrom(formSpec)
        XCTAssert(result)

        guard let affirmUpdated = sut.formSpec(for: paymentMethodType),
              affirmUpdated.fields.count == 1,
              affirmUpdated.fields.first
                == .name(FormSpec.NameFieldSpec(apiPath: nil, translationId: nil)),
              affirmUpdated.nextActionSpec == nil
        else {
            XCTFail()
            return
        }
    }

    func testLoadJsonDoesNotOverwriteWhenWithUnsupportedNextAction() throws {
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
        guard
            case .redirect_to_url(let redirectToURLDetails) = eps.nextActionSpec?.confirmResponseStatusSpecs[
                "requires_action"
            ]?.type,
            case .finished = eps.nextActionSpec?.postConfirmHandlingPiStatusSpecs?["succeeded"]?
                .type,
            case .canceled = eps.nextActionSpec?.postConfirmHandlingPiStatusSpecs?[
                "requires_action"
            ]?.type
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(redirectToURLDetails.redirectStrategy, .none)
        XCTAssertEqual(redirectToURLDetails.urlPath, "next_action[redirect_to_url][url]")
        XCTAssertEqual(redirectToURLDetails.returnUrlPath, "next_action[redirect_to_url][return_url]")

        let updatedSpecJsonWithUnsupportedNextAction =
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
                            "type": "redirect_to_url_v2_NotSupported"
                        }
                    },
                    "post_confirm_handling_pi_status_specs": {
                        "succeeded": {
                            "type": "finished"
                        },
                        "requires_action": {
                            "type": "canceled"
                        }
                    }
                }
            }]
            """.data(using: .utf8)!
        let formSpec =
        try! JSONSerialization.jsonObject(with: updatedSpecJsonWithUnsupportedNextAction)
        as! [NSDictionary]
        let result = sut.loadFrom(formSpec)
        XCTAssertFalse(result)

        // Validate that we were not able to override the spec read in from disk
        let epsUpdated = try XCTUnwrap(sut.formSpec(for: paymentMethodType))
        XCTAssertEqual(epsUpdated.fields.count, 5)
        XCTAssertEqual(
            epsUpdated.fields.first,
            .name(FormSpec.NameFieldSpec(apiPath: ["v1": "billing_details[name]"], translationId: nil))
        )
        guard
            case .redirect_to_url = epsUpdated.nextActionSpec?.confirmResponseStatusSpecs[
                "requires_action"
            ]?.type,
            case .finished = epsUpdated.nextActionSpec?.postConfirmHandlingPiStatusSpecs?[
                "succeeded"
            ]?.type,
            case .canceled = epsUpdated.nextActionSpec?.postConfirmHandlingPiStatusSpecs?[
                "requires_action"
            ]?.type
        else {
            XCTFail()
            return
        }
    }
    func testContainsKnownNextAction() throws {
        let formSpec =
            """
            [{
                "type": "eps",
                "async": false,
                "fields": [
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
                            "type": "canceled"
                        }
                    }
                }
            }]
            """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decodedFormSpecs = try decoder.decode([FormSpec].self, from: formSpec)

        let sut = FormSpecProvider()
        XCTAssertFalse(sut.containsUnknownNextActions(formSpecs: decodedFormSpecs))
    }

    func testContainsUnknownNextAction_confirm() throws {
        let formSpec =
            """
            [{
                "type": "eps",
                "async": false,
                "fields": [
                ],
                "next_action_spec": {
                    "confirm_response_status_specs": {
                        "requires_action": {
                            "type": "redirect_to_url_v2_NotSupported"
                        }
                    },
                    "post_confirm_handling_pi_status_specs": {
                        "succeeded": {
                            "type": "finished"
                        },
                        "requires_action": {
                            "type": "canceled"
                        }
                    }
                }
            }]
            """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decodedFormSpecs = try decoder.decode([FormSpec].self, from: formSpec)

        let sut = FormSpecProvider()
        XCTAssert(sut.containsUnknownNextActions(formSpecs: decodedFormSpecs))
    }

    func testContainsUnknownNextAction_PostConfirm() throws {
        let formSpec =
            """
            [{
                "type": "eps",
                "async": false,
                "fields": [
                ],
                "next_action_spec": {
                    "confirm_response_status_specs": {
                        "requires_action": {
                            "type": "redirect_to_url"
                        }
                    },
                    "post_confirm_handling_pi_status_specs": {
                        "succeeded": {
                            "type": "finished_NotSupportedType"
                        },
                        "requires_action": {
                            "type": "canceled"
                        }
                    }
                }
            }]
            """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decodedFormSpecs = try decoder.decode([FormSpec].self, from: formSpec)

        let sut = FormSpecProvider()
        XCTAssert(sut.containsUnknownNextActions(formSpecs: decodedFormSpecs))
    }
    func testRedirectToURLWithExternalBrowserStrategy() throws {
        let formSpec =
            """
            [{
                "type": "eps",
                "async": false,
                "fields": [
                ],
                "next_action_spec": {
                    "confirm_response_status_specs": {
                        "requires_action": {
                            "type": "redirect_to_url",
                            "native_mobile_redirect_strategy": "external_browser"
                        }
                    },
                    "post_confirm_handling_pi_status_specs": {
                        "succeeded": {
                            "type": "finished"
                        }
                    }
                }
            }]
            """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let eps = try decoder.decode([FormSpec].self, from: formSpec).first

        guard case let .redirect_to_url(redirectToURL) = eps?.nextActionSpec?.confirmResponseStatusSpecs["requires_action"]?.type else {
            XCTFail("Unable to parse requires_action")
            return
        }
        XCTAssertEqual(redirectToURL.redirectStrategy, .external_browser)
        XCTAssertEqual(redirectToURL.urlPath, "next_action[redirect_to_url][url]")
        XCTAssertEqual(redirectToURL.returnUrlPath, "next_action[redirect_to_url][return_url]")
    }
    func testRedirectToURLWithFollowRedirectsStrategy() throws {
        let formSpec =
            """
            [{
                "type": "eps",
                "async": false,
                "fields": [
                ],
                "next_action_spec": {
                    "confirm_response_status_specs": {
                        "requires_action": {
                            "type": "redirect_to_url",
                            "native_mobile_redirect_strategy": "follow_redirects"
                        }
                    },
                    "post_confirm_handling_pi_status_specs": {
                        "succeeded": {
                            "type": "finished"
                        }
                    }
                }
            }]
            """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let eps = try decoder.decode([FormSpec].self, from: formSpec).first

        guard case let .redirect_to_url(redirectToURL) = eps?.nextActionSpec?.confirmResponseStatusSpecs["requires_action"]?.type else {
            XCTFail("Unable to parse requires_action")
            return
        }
        XCTAssertEqual(redirectToURL.redirectStrategy, .follow_redirects)
        XCTAssertEqual(redirectToURL.urlPath, "next_action[redirect_to_url][url]")
        XCTAssertEqual(redirectToURL.returnUrlPath, "next_action[redirect_to_url][return_url]")
    }
}
