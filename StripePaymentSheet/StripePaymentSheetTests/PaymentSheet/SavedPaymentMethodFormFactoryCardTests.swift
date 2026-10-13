//
//  SavedPaymentMethodFormFactoryCardTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) @testable import StripePaymentsUI
@testable@_spi(STP) import StripeUICore
import XCTest

@MainActor
final class SavedPaymentMethodFormFactoryCardTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - Card section title

    func testTitleIsProgramNameWhenBillingSectionIsShown() {
        // Given a card with a program name, on a screen that also shows the billing address section
        let cardSection = makeCardSection(paymentMethod: STPPaymentMethod._testCardWithCardArt(), canUpdate: true)

        // Then the program name replaces "Card information"
        XCTAssertEqual(cardSection.title, "Test Program")
    }

    func testTitleIsProgramNameWhenThereIsNoBillingSection() {
        // Given a card with a program name, on a screen with no billing address section (eg brand-only edits)
        let cardSection = makeCardSection(paymentMethod: STPPaymentMethod._testCardWithCardArt(), canUpdate: false)

        // Then the program name is still shown, even though there would otherwise be no header at all
        XCTAssertEqual(cardSection.title, "Test Program")
    }

    func testTitleIsCardInformationWithoutAProgramName() {
        // Given a card with no program name, on a screen that shows the billing address section
        let cardSection = makeCardSection(paymentMethod: STPPaymentMethod._testCard(), canUpdate: true)

        // Then the existing "Card information" title is used
        XCTAssertEqual(cardSection.title, String.Localized.card_information)
    }

    func testTitleIsNilWithoutAProgramNameOrBillingSection() {
        // Given a card with no program name and no billing address section
        let cardSection = makeCardSection(paymentMethod: STPPaymentMethod._testCard(), canUpdate: false)

        // Then there is no header, matching the behavior before program names existed
        XCTAssertNil(cardSection.title)
    }

    func testTitleIsNilWhenAddressCollectionIsNever() {
        // Given a card with no program name, and a merchant who has disabled address collection...
        let cardSection = makeCardSection(
            paymentMethod: STPPaymentMethod._testCard(),
            canUpdate: true,
            addressCollectionMode: .never
        )

        // ...then there is no billing section and so no header, even though updates are allowed
        XCTAssertNil(cardSection.title)
    }

    func testTitleIsProgramNameForCustomerSheet() {
        // Given a card with a program name, on CustomerSheet's copy of the manage card screen
        let cardSection = makeCardSection(
            paymentMethod: STPPaymentMethod._testCardWithCardArt(),
            canUpdate: true,
            hostedSurface: .customerSheet
        )

        // Then the program name is shown, same as in PaymentSheet
        XCTAssertEqual(cardSection.title, "Test Program")
    }

    // MARK: - Helpers

    /// Builds the card form and returns its card section, which is always the first element.
    private func makeCardSection(
        paymentMethod: STPPaymentMethod,
        canUpdate: Bool,
        addressCollectionMode: PaymentSheet.BillingDetailsCollectionConfiguration.AddressCollectionMode = .automatic,
        hostedSurface: HostedSurface = .paymentSheet
    ) -> SectionElement {
        let billingDetailsCollectionConfiguration = PaymentSheet.BillingDetailsCollectionConfiguration(
            name: .never,
            phone: .never,
            email: .never,
            address: addressCollectionMode
        )
        let configuration = UpdatePaymentMethodViewController.Configuration(
            paymentMethod: paymentMethod,
            appearance: .default,
            billingDetailsCollectionConfiguration: billingDetailsCollectionConfiguration,
            hostedSurface: hostedSurface,
            canRemove: true,
            canUpdate: canUpdate,
            isCBCEligible: false
        )
        let form = SavedPaymentMethodFormFactory().makePaymentMethodForm(configuration: configuration) as! FormElement
        return form.elements.first as! SectionElement
    }
}
