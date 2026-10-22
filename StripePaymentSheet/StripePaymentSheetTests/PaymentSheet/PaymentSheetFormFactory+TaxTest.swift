//
//  PaymentSheetFormFactory+TaxTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 7/18/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore

@MainActor
final class PaymentSheetFormFactoryTaxTest: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        await PaymentSheetLoader.loadMiscellaneousSingletons()
    }

    func testAllSupportedLPMsCollectMinimumTaxFields() {
        // Given automatic tax sourced from the Checkout Session billing address
        let intent = makeCheckoutIntent()
        let configuration = makeConfiguration(country: "US")

        // When every supported LPM builds its production form
        for paymentMethod in PaymentSheet.supportedPaymentMethods {
            let form = makeForm(paymentMethod: paymentMethod, intent: intent, configuration: configuration)
            let addressSections = addressSections(in: form)
            XCTAssertEqual(
                addressSections.count,
                1,
                "\(paymentMethod.identifier) must collect exactly one billing address for automatic tax"
            )

            // Then every billing address in the form collects the selected country's tax minimum
            for addressSection in addressSections {
                switch addressSection.selectedCountryCode {
                case "US", "PR":
                    XCTAssertTrue(
                        addressSection.line1 != nil || addressSection.autoCompleteLine != nil,
                        "\(paymentMethod.identifier) must collect a full address"
                    )
                case "CA", "GB", "IN":
                    XCTAssertNotNil(
                        addressSection.postalCode,
                        "\(paymentMethod.identifier) must collect a postal code"
                    )
                default:
                    break
                }
            }
        }
    }

    func testSpecializedPaymentMethodFormsBuildTaxAddressInternally() {
        let paymentMethods: [PaymentSheet.PaymentMethodType] = [
            .instantDebits,
            .linkCardBrand,
            .stripe(.USBankAccount),
        ]

        for paymentMethod in paymentMethods {
            let form = PaymentSheetFormFactory(
                intent: makeCheckoutIntent(),
                elementsSession: ._testCardValue(),
                configuration: .paymentElement(makeConfiguration(country: "US")),
                paymentMethod: paymentMethod
            ).make()

            XCTAssertFalse(form is FormElement)
            XCTAssertEqual(addressSections(in: form).count, 1)
        }
    }

    func testTaxMinimumsOnlyApplyToCheckoutAutomaticTaxFromBilling() {
        let configuration = makeConfiguration(country: "US")
        let cases: [(intent: Intent, expectsAddress: Bool)] = [
            (._testValue(), false),
            (makeCheckoutIntent(automaticTaxEnabled: false), false),
            (makeCheckoutIntent(addressSource: "session.shipping"), false),
            (makeCheckoutIntent(), true),
        ]

        for testCase in cases {
            // BLIK does not ordinarily collect an address for `.automatic`.
            let form = makeForm(paymentMethod: .blik, intent: testCase.intent, configuration: configuration)
            XCTAssertEqual(addressSections(in: form).isEmpty, !testCase.expectsAddress)
        }
    }

    func testCountryTaxMinimums() throws {
        let expectations: [(country: String, collectsFullAddress: Bool, collectsPostalCode: Bool)] = [
            ("US", true, true),
            ("PR", true, true),
            ("CA", false, true),
            ("GB", false, true),
            ("IN", false, true),
            ("FR", false, false),
        ]

        for expectation in expectations {
            let form = makeForm(
                paymentMethod: .card,
                intent: makeCheckoutIntent(),
                configuration: makeConfiguration(country: expectation.country)
            )
            let addressSection = try XCTUnwrap(addressSections(in: form).first)

            XCTAssertEqual(
                addressSection.line1 != nil || addressSection.autoCompleteLine != nil,
                expectation.collectsFullAddress,
                "Unexpected full-address collection for \(expectation.country)"
            )
            XCTAssertEqual(
                addressSection.postalCode != nil || addressSection.autoCompleteLine != nil,
                expectation.collectsPostalCode,
                "Unexpected postal-code collection for \(expectation.country)"
            )
        }
    }

    func testTaxAddressSectionUpdatesBillingParams() throws {
        let form = makeForm(
            paymentMethod: .blik,
            intent: makeCheckoutIntent(),
            configuration: makeConfiguration(country: "CA")
        )
        let outerForm = try XCTUnwrap(form as? FormElement)
        let addressSection: AddressSectionElement = try XCTUnwrap(outerForm.getElement())
        let blikCode: TextFieldElement = outerForm.getTextFieldElement(String.Localized.blik_code)
        blikCode.setText("123456")
        addressSection.postalCode?.setText("A1A 1A1")

        let params = outerForm.updateParams(params: IntentConfirmParams(type: .stripe(.blik)))

        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.address?.country, "CA")
        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.address?.postalCode, "A1A 1A1")
    }

    private func makeCheckoutIntent(
        automaticTaxEnabled: Bool = true,
        addressSource: String = "session.billing"
    ) -> Intent {
        ._testCheckoutSession(
            automaticTaxEnabled: automaticTaxEnabled,
            automaticTaxAddressSource: addressSource
        )
    }

    private func makeConfiguration(country: String) -> PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.address = .automatic
        configuration.defaultBillingDetails.address.country = country
        return configuration
    }

    private func makeForm(
        paymentMethod: STPPaymentMethodType,
        intent: Intent,
        configuration: PaymentSheet.Configuration
    ) -> PaymentMethodElement {
        makeFactory(
            paymentMethod: paymentMethod,
            intent: intent,
            configuration: configuration
        ).make()
    }

    private func makeFactory(
        paymentMethod: STPPaymentMethodType,
        intent: Intent,
        configuration: PaymentSheet.Configuration
    ) -> PaymentSheetFormFactory {
        PaymentSheetFormFactory(
            intent: intent,
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(configuration),
            paymentMethod: .stripe(paymentMethod)
        )
    }

    private func addressSections(in form: PaymentMethodElement) -> [AddressSectionElement] {
        form.getAllUnwrappedSubElements().compactMap { $0 as? AddressSectionElement }
    }
}
