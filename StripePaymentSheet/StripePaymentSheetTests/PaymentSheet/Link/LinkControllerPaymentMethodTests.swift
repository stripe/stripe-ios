//
//  LinkControllerPaymentMethodTests.swift
//  StripePaymentSheetTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class LinkControllerPaymentMethodTests: APIStubbedTestCase {
    private var paymentMethodRequests: [URLRequest] = []
    private var onPaymentMethodRequest: (@MainActor () -> Void)?

    override func tearDown() {
        onPaymentMethodRequest = nil
        LinkAccountContext.shared.account = nil
        super.tearDown()
    }

    @MainActor
    func testCardSummariesUseUnderlyingFundingForBothCreationModes() async throws {
        let cases: [(ConsumerPaymentDetails.Details.Card.Funding, STPCardFundingType)] = [
            (.debit, .debit), (.credit, .credit), (.prepaid, .prepaid), (.unparsable, .other),
        ]
        for passthrough in [false, true] {
            let controller = try await makeController(passthrough: passthrough)
            for (funding, expectedFunding) in cases {
                // Given either a newly entered card carrying CVC or a saved card without it
                for cvc in [nil, "123"] as [String?] {
                    let card = ConsumerPaymentDetails.Details.Card(
                        expiryYear: 2030, expiryMonth: 12, brand: "visa", networks: ["visa"],
                        last4: "4242", funding: funding, checks: nil
                    )
                    card.cvc = cvc
                    let selection = paymentDetails(id: "payment_details_card_test", details: .card(card: card))
                    try select(selection, on: controller)

                    // When the created PaymentMethod is a Link wrapper
                    let result = try await controller.createPaymentMethodForOnramp()

                    // Then metadata describes only the underlying card, not the wrapper
                    XCTAssertEqual(result.paymentMethod.type, .link)
                    guard case let .card(funding, brand, last4) = result.details else {
                        return XCTFail("Expected a card summary")
                    }
                    XCTAssertEqual(funding, expectedFunding)
                    XCTAssertEqual(brand, .visa)
                    XCTAssertEqual(last4, "4242")
                    assertRequestedSelection(selection, passthrough: passthrough)
                }
            }
        }
        XCTAssertEqual(paymentMethodRequests.count, 16)
    }

    @MainActor
    func testCreateAndShareKeepSnapshotWhenCardAndBankSelectionsSwitch() async throws {
        let card = paymentDetails(id: "payment_details_card_test", details: .card(card: .init(
            expiryYear: 2030, expiryMonth: 12, brand: "visa", networks: ["visa"],
            last4: "4242", funding: .debit, checks: nil
        )))
        let bank = paymentDetails(id: "payment_details_bank_test", details: .bankAccount(bankAccount: .init(
            iconCode: nil, name: "", last4: "6789", country: "COUNTRY_US"
        )))
        for passthrough in [false, true] {
            let controller = try await makeController(passthrough: passthrough)
            for original in [card, bank] {
                // Given a captured instrument and a different replacement selection
                try select(original, on: controller)
                let replacement = original === card ? bank : card
                let account = try XCTUnwrap(LinkAccountContext.shared.account)
                onPaymentMethodRequest = {
                    controller.internalPaymentOption = .link(option: .withPaymentDetails(
                        brand: .link, account: account, paymentDetails: replacement,
                        confirmationExtras: nil, shippingAddress: nil
                    ))
                }

                // When selection changes after the request starts but before it responds
                let result = try await controller.createPaymentMethodForOnramp()
                onPaymentMethodRequest = nil

                // Then both the submitted ID and returned snapshot refer to the original instrument
                XCTAssertEqual(result.paymentMethod.stripeId, "pm_link_test")
                XCTAssertEqual(result.paymentMethod.type, .link)
                assertRequestedSelection(original, passthrough: passthrough)
                switch result.details {
                case let .card(funding, brand, last4):
                    XCTAssertTrue(original === card)
                    XCTAssertEqual(funding, .debit)
                    XCTAssertEqual(brand, .visa)
                    XCTAssertEqual(last4, "4242")
                case let .bankAccount(last4):
                    XCTAssertTrue(original === bank)
                    XCTAssertEqual(last4, "6789")
                case nil:
                    XCTFail("Expected the captured instrument summary")
                }

                // ...and the existing PaymentMethod-only API uses the replacement selection
                let legacy = try await controller.createPaymentMethod()
                XCTAssertEqual(legacy.stripeId, result.paymentMethod.stripeId)
                assertRequestedSelection(replacement, passthrough: passthrough)
            }
        }
        XCTAssertEqual(paymentMethodRequests.count, 8)
    }

    @MainActor
    func testUnsupportedInstrumentReturnsPaymentMethodWithoutSummary() async throws {
        for passthrough in [false, true] {
            let controller = try await makeController(passthrough: passthrough)
            let selection = paymentDetails(id: "payment_details_generic_test", details: .generic(rawValue: "UNKNOWN"))
            try select(selection, on: controller)

            let result = try await controller.createPaymentMethodForOnramp()

            XCTAssertEqual(result.paymentMethod.stripeId, "pm_link_test")
            XCTAssertNil(result.details)
            assertRequestedSelection(selection, passthrough: passthrough)
        }
        XCTAssertEqual(paymentMethodRequests.count, 2)
    }

    @MainActor
    private func makeController(passthrough: Bool) async throws -> LinkController {
        LinkAccountContext.shared.account = nil
        let elementsSession: [String: Any] = [
            "config_id": "config_test",
            "link_settings": [
                "link_funding_sources": ["CARD", "BANK_ACCOUNT"],
                "link_passthrough_mode_enabled": passthrough,
            ],
            "merchant_country": "US",
            "ordered_payment_method_types_and_wallets": ["card"],
            "payment_method_preference": [
                "country_code": "US",
                "object": "payment_method_preference",
                "ordered_payment_method_types": ["card"],
                "type": "deferred_intent",
            ],
            "session_id": "elements_session_test",
        ]
        stub { $0.url?.path == "/v1/elements/sessions" } response: { _ in
            HTTPStubsResponse(jsonObject: elementsSession, statusCode: 200, headers: nil)
        }
        let path = passthrough ? "/v1/consumers/payment_details/share" : "/v1/payment_methods"
        stub { $0.url?.path == path } response: { [self] request in
            paymentMethodRequests.append(request)
            if let onPaymentMethodRequest {
                if Thread.isMainThread {
                    MainActor.assumeIsolated { onPaymentMethodRequest() }
                } else {
                    DispatchQueue.main.sync { onPaymentMethodRequest() }
                }
            }
            let paymentMethod: [String: Any] = ["id": "pm_link_test", "type": "link", "link": [:]]
            return HTTPStubsResponse(
                jsonObject: passthrough ? ["payment_method": paymentMethod] : paymentMethod,
                statusCode: 200, headers: nil
            )
        }
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_example"
        let controller = try await LinkController.create(apiClient: apiClient, mode: .payment, requestSurface: .cryptoOnramp)
        LinkAccountContext.shared.account = LinkStubs.account()
        return controller
    }

    @MainActor
    private func select(_ details: ConsumerPaymentDetails, on controller: LinkController) throws {
        let account = try XCTUnwrap(LinkAccountContext.shared.account)
        controller.internalPaymentOption = .link(option: .withPaymentDetails(
            brand: .link, account: account, paymentDetails: details,
            confirmationExtras: nil, shippingAddress: nil
        ))
    }

    private func paymentDetails(id: String, details: ConsumerPaymentDetails.Details) -> ConsumerPaymentDetails {
        return ConsumerPaymentDetails(
            stripeID: id, details: details,
            billingAddress: nil, billingEmailAddress: nil, nickname: nil, isDefault: false
        )
    }

    private func assertRequestedSelection(
        _ selection: ConsumerPaymentDetails,
        passthrough: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let body = paymentMethodRequests.last?.ohhttpStubs_httpBody.flatMap { String(data: $0, encoding: .utf8) }
        let parameters = URLComponents(string: "https://example.com/?\(body ?? "")")?.queryItems
        let key = passthrough ? "id" : "link[payment_details_id]"
        XCTAssertEqual(parameters?.first { $0.name == key }?.value, selection.stripeID, file: file, line: line)
    }
}
