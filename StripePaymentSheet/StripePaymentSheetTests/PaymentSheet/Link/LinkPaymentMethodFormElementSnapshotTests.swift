//
//  LinkPaymentMethodFormElementSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 10/3/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripeUICore

// @iOS26
final class LinkPaymentMethodFormElementSnapshotTests: STPSnapshotTestCase {

    override static func setUp() {
        if #available(iOS 26, *) {
            var configuration = PaymentSheet.Configuration()
            configuration.appearance.applyLiquidGlass()
            LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        }
    }

    override func setUp() {
        super.setUp()
        // `LinkPaymentMethodFormElement` depends on `AddressSectionElement`, which requires
        // address specs to be loaded in memory.
        let expectation = expectation(description: "Load address specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testDefault() {
        let sut = makeSUT(isDefault: true)
        verify(sut)
    }

    func testNonDefault() {
        let sut = makeSUT(isDefault: false)
        verify(sut)
    }

    func testBillingDetailsUpdate() {
        let sut = makeSUT(isDefault: false, isBillingDetailsUpdateFlow: true)
        verify(sut)
    }

    func testBillingDetailsUpdateWithPartialBillingDetails() {
        let sut = makeSUT(
            isDefault: false,
            isBillingDetailsUpdateFlow: true,
            requestName: true,
            requestPhone: true
        )
        verify(sut)
    }

    func testBillingDetailsUpdateWithFullBillingDetails() {
        let sut = makeSUT(
            isDefault: false,
            isBillingDetailsUpdateFlow: true,
            requestName: true,
            requestPhone: true,
            requestEmail: true,
            requestFullAddress: true
        )
        verify(sut)
    }

    func testCoBrandedCard() {
        let sut = makeSUT(isDefault: false, networks: ["cartes_bancaires", "visa"])
        verify(sut)
    }

    func testBillingDetailsUpdateForBankAccount() {
        let sut = makeBankAccountSUT()
        verify(sut)
    }

    func testBillingDetailsUpdateParamsPreserveExistingNameWhenNameIsAutomatic() {
        let sut = makeSUT(
            isDefault: false,
            isBillingDetailsUpdateFlow: true,
            requestFullAddress: true,
            billingAddress: BillingAddress(
                name: "Jane Doe",
                line1: "510 Townsend St.",
                city: "San Francisco",
                state: "CA",
                postalCode: "94103",
                countryCode: "US"
            )
        )

        guard let params = sut.params else {
            XCTFail("Expected valid params")
            return
        }

        let name = params.billingDetails.value(forKey: "name") as? String
        XCTAssertEqual(name, "Jane Doe")
    }

    func verify(
        _ element: LinkPaymentMethodFormElement,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        element.view.autosizeHeight(width: 340)
        STPSnapshotVerifyView(element.view, identifier: identifier, file: file, line: line)
    }

    func testBillingDetailsUpdateWithAutomaticTaxCollectsOnlyFieldsTaxRequiresForCountry() throws {
        let cases: [(country: String, collectsPostalCode: Bool, collectsFullAddress: Bool)] = [
            ("DE", false, false),
            ("CA", true, false),
            ("US", true, true),
        ]
        for testCase in cases {
            // Given a Link card whose billing address only has a country, and tax calculated from the billing address
            // When the customer is asked to complete its billing details
            let sut = makeSUT(
                isDefault: false,
                isBillingDetailsUpdateFlow: true,
                collectsTaxFromBillingAddress: true,
                billingAddress: BillingAddress(countryCode: testCase.country)
            )

            // Then the form collects the fields tax requires for that country, without the merchant requesting a full address
            let addressSection = try XCTUnwrap(sut.billingAddressSection, testCase.country)
            XCTAssertEqual(addressSection.postalCode != nil, testCase.collectsPostalCode, testCase.country)
            XCTAssertEqual(addressSection.line1 != nil, testCase.collectsFullAddress, testCase.country)
            XCTAssertEqual(addressSection.city != nil, testCase.collectsFullAddress, testCase.country)
        }
    }
}

extension LinkPaymentMethodFormElementSnapshotTests {

    func makeSUT(
        isDefault: Bool,
        isBillingDetailsUpdateFlow: Bool = false,
        requestName: Bool = false,
        requestPhone: Bool = false,
        requestEmail: Bool = false,
        requestFullAddress: Bool = false,
        collectsTaxFromBillingAddress: Bool = false,
        billingAddress: BillingAddress? = nil,
        networks: [String] = ["visa"]
    ) -> LinkPaymentMethodFormElement {
        let paymentMethod = ConsumerPaymentDetails(
            stripeID: "1",
            details: .card(
                card: .init(
                    expiryYear: 2032,
                    expiryMonth: 1,
                    brand: "visa",
                    networks: networks,
                    last4: "4242",
                    funding: .credit,
                    checks: nil
                )
            ),
            billingAddress: billingAddress,
            billingEmailAddress: nil,
            nickname: nil,
            isDefault: isDefault
        )

        var configuration = PaymentSheet.Configuration()
        if requestFullAddress {
            configuration.billingDetailsCollectionConfiguration.address = .full
        }
        if requestEmail {
            configuration.billingDetailsCollectionConfiguration.email = .always
        }
        if requestName {
            configuration.billingDetailsCollectionConfiguration.name = .always
        }
        if requestPhone {
            configuration.billingDetailsCollectionConfiguration.phone = .always
        }
        return LinkPaymentMethodFormElement(
            paymentMethod: paymentMethod,
            configuration: configuration,
            isBillingDetailsUpdateFlow: isBillingDetailsUpdateFlow,
            collectsTaxFromBillingAddress: collectsTaxFromBillingAddress
        )
    }

    func makeBankAccountSUT() -> LinkPaymentMethodFormElement {
        let paymentMethod = ConsumerPaymentDetails(
            stripeID: "1",
            details: .bankAccount(
                bankAccount: .init(
                    iconCode: nil,
                    name: "Stripe Bank",
                    last4: "6789",
                    country: "COUNTRY_US"
                )
            ),
            billingAddress: BillingAddress(
                name: "Jane Doe"
            ),
            billingEmailAddress: nil,
            nickname: nil,
            isDefault: false
        )

        var config = PaymentSheet.Configuration()
        config.billingDetailsCollectionConfiguration.address = .full
        config.billingDetailsCollectionConfiguration.email = .always
        config.billingDetailsCollectionConfiguration.name = .always
        config.billingDetailsCollectionConfiguration.phone = .always

        return LinkPaymentMethodFormElement(
            paymentMethod: paymentMethod,
            configuration: config,
            isBillingDetailsUpdateFlow: true
        )
    }
}
