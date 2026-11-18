//
//  StripeBalanceTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 11/12/26.
//

import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripeUICore

@MainActor
final class StripeBalanceTests: XCTestCase {

    // MARK: - Decoding

    func testDecodesFinancialAccounts() throws {
        // Given the response shape served by `v1/elements/stripe_balance/customer_session/financial_accounts`
        let json = """
        {
          "object": "list",
          "has_more": false,
          "data": [
            {
              "object": "stripe_balance.financial_account",
              "id": "fa_operating",
              "display_name": "Operating account",
              "status": "OPEN",
              "balance": {"available": {"usd": {"value": 25000, "currency": "usd"}}},
              "eligible": true,
              "ineligible_reason": null
            },
            {
              "object": "stripe_balance.financial_account",
              "id": "fa_reserve",
              "display_name": null,
              "balance": {"available": {"usd": {"value": 2500, "currency": "usd"}}},
              "eligible": false,
              "ineligible_reason": "insufficient_balance"
            },
            {
              "id": "fa_gbp",
              "balance": {"available": {"gbp": {"value": 100, "currency": "gbp"}}},
              "eligible": false,
              "ineligible_reason": "some_future_reason"
            },
            {
              "id": "fa_untagged",
              "balance": {"available": {"usd": {"value": 100, "currency": "usd"}}}
            }
          ]
        }
        """
        struct List: Decodable { let data: [StripeBalanceFinancialAccount] }

        // When
        let accounts = try StripeJSONDecoder().decode(List.self, from: Data(json.utf8)).data

        // Then
        XCTAssertEqual(accounts.map(\.id), ["fa_operating", "fa_reserve", "fa_gbp", "fa_untagged"])
        XCTAssertEqual(accounts[0].displayName, "Operating account")
        XCTAssertEqual(accounts[0].availableBalance(in: "USD"), .init(value: 25000, currency: "usd"))
        XCTAssertTrue(accounts[0].isSelectable)
        XCTAssertNil(accounts[1].displayName)
        XCTAssertEqual(accounts[1].ineligibleReason, .insufficientBalance)
        XCTAssertFalse(accounts[1].isSelectable)
        // ...and accounts missing optional fields or with unknown reasons still decode
        XCTAssertNil(accounts[2].displayName)
        XCTAssertEqual(accounts[2].ineligibleReason, .unparsable)
        XCTAssertNil(accounts[2].availableBalance(in: "usd"))
        // ...and an account the server didn't tag as eligible or not can be selected
        XCTAssertNil(accounts[3].eligible)
        XCTAssertTrue(accounts[3].isSelectable)
    }

    // MARK: - Availability

    func testRequiresCustomerSessionForPaymentsAndSetup() {
        // Given
        let paymentIntent = Intent._testPaymentIntent(paymentMethodTypes: [.stripeBalance])
        var legacyCustomerConfiguration = PaymentSheet.Configuration()
        legacyCustomerConfiguration.customer = .init(id: "cus_123", ephemeralKeySecret: "ek_123")

        // When
        let withoutCustomer = supportsAdding(intent: paymentIntent, configuration: PaymentSheet.Configuration())
        let withLegacyEphemeralKey = supportsAdding(intent: paymentIntent, configuration: legacyCustomerConfiguration)
        let withCustomerSession = supportsAdding(intent: paymentIntent, configuration: makeCustomerSessionConfiguration())

        // Then
        XCTAssertEqual(withoutCustomer, .missingRequirements([.customerSession]))
        XCTAssertEqual(withLegacyEphemeralKey, .missingRequirements([.customerSession]))
        XCTAssertEqual(withCustomerSession, .supported)
        let setupIntents: [Intent] = [
            ._testPaymentIntent(paymentMethodTypes: [.stripeBalance], setupFutureUsage: .offSession),
            ._testSetupIntent(paymentMethodTypes: [.stripeBalance]),
        ]
        // ...and setting up for future use works the same way
        for intent in setupIntents {
            XCTAssertEqual(supportsAdding(intent: intent, configuration: makeCustomerSessionConfiguration()), .supported)
            XCTAssertEqual(supportsAdding(intent: intent, configuration: PaymentSheet.Configuration()), .missingRequirements([.customerSession]))
        }
    }

    // MARK: - Loading

    func testOnlyFetchesAccountsWhenStripeBalanceIsOfferedWithACustomerSession() async {
        // Given
        let paymentIntent = Intent._testPaymentIntent(paymentMethodTypes: [.stripeBalance])
        let configuration = makeCustomerSessionConfiguration()
        let elementsSessionWithCustomerSession = makeElementsSessionWithCustomerSession()
        func didFetch(
            intent: Intent = paymentIntent,
            elementsSession: STPElementsSession = elementsSessionWithCustomerSession,
            configuration: PaymentSheet.Configuration = configuration
        ) async -> Bool {
            let loadTimings = PaymentSheetLoader.LoadTimings()
            let financialAccounts = await PaymentSheetLoader.fetchStripeBalanceFinancialAccounts(
                intent: intent,
                elementsSession: elementsSession,
                configuration: configuration,
                analyticsHelper: .init(integrationShape: .complete, configuration: configuration),
                loadTimings: loadTimings
            )
            XCTAssertNil(financialAccounts)
            return loadTimings.jsonObject["fetchStripeBalanceFinancialAccounts"] != nil
        }

        // Then nothing is fetched when Stripe balance isn't offered
        let notOffered = await didFetch(elementsSession: makeElementsSessionWithCustomerSession(paymentMethodTypes: ["card"]))
        XCTAssertFalse(notOffered)
        // ...or the merchant didn't use a CustomerSession
        let withoutCustomerSession = await didFetch(configuration: PaymentSheet.Configuration())
        XCTAssertFalse(withoutCustomerSession)
        // ...or ElementsSession didn't return one, e.g. a fallback ElementsSession
        let fallbackElementsSession = await didFetch(elementsSession: ._testValue(paymentMethodTypes: ["stripe_balance"]))
        XCTAssertFalse(fallbackElementsSession)
    }

    // MARK: - Helpers

    private func makeCustomerSessionConfiguration() -> PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "cus_123", customerSessionClientSecret: "cuss_123_secret_456")
        return configuration
    }

    private func makeElementsSessionWithCustomerSession(paymentMethodTypes: [String] = ["stripe_balance"]) -> STPElementsSession {
        ._testValue(
            paymentMethodTypes: paymentMethodTypes,
            customerSessionData: [
                "mobile_payment_element": [
                    "enabled": true,
                    "features": ["payment_method_save": "disabled", "payment_method_remove": "disabled"],
                ],
                "customer_sheet": ["enabled": false],
            ]
        )
    }

    private func supportsAdding(intent: Intent, configuration: PaymentSheet.Configuration) -> PaymentSheet.PaymentMethodAvailabilityStatus {
        PaymentSheet.PaymentMethodType.supportsAdding(
            paymentMethod: .stripeBalance,
            configuration: configuration,
            intent: intent,
            elementsSession: ._testValue(intent: intent),
            supportedPaymentMethods: [.stripeBalance]
        )
    }
}
