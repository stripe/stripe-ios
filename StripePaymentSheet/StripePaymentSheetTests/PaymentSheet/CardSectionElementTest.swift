//
//  CardSectionElementTest.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 3/5/26.
//

@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripeUICore
import XCTest

class CardSectionElementTest: XCTestCase {

    // CBC test card that returns [.cartesBancaires, .visa]
    let cbcVisaTestCard = "4000002500001001"

    private func makeCardSectionElement(
        preferredNetworks: [STPCardBrand]? = nil,
        cardBrandFilter: CardBrandFilter = .default
    ) -> CardSectionElement {
        return CardSectionElement(
            collectName: false,
            defaultValues: .init(),
            preferredNetworks: preferredNetworks,
            cardBrandChoiceEligible: true,
            enableCBCRedesign: true,
            hostedSurface: .paymentSheet,
            theme: .default,
            analyticsHelper: ._testValue(),
            cardBrandFilter: cardBrandFilter,
            opensCardScannerAutomatically: false
        )
    }

    // MARK: - Preferred networks

    func testPreferredNetwork_selectsPreferredBrand() {
        let cardSection = makeCardSectionElement(preferredNetworks: [.cartesBancaires, .visa])
        cardSection.panElement.setText(cbcVisaTestCard)
        XCTAssertEqual(cardSection.cardBrandChoiceElement?.selectedBrand, .cartesBancaires)
    }

    func testPreferredNetwork_skipsDisallowedPreferred() {
        let filter = CardBrandFilter(cardBrandAcceptance: .disallowed(brands: [.visa]))
        let cardSection = makeCardSectionElement(preferredNetworks: [.visa, .cartesBancaires], cardBrandFilter: filter)
        cardSection.panElement.setText(cbcVisaTestCard)
        XCTAssertEqual(cardSection.cardBrandChoiceElement?.selectedBrand, .cartesBancaires)
    }

    func testPreferredNetwork_noSelectionWhenPreferredNotFetched() {
        let cardSection = makeCardSectionElement(preferredNetworks: [.mastercard])
        cardSection.panElement.setText(cbcVisaTestCard)
        XCTAssertNil(cardSection.cardBrandChoiceElement?.selectedBrand)
    }

    // MARK: - Card brand filtering autoselection

    func testFiltering_autoselectsOnlyAllowedBrand() {
        let filter = CardBrandFilter(cardBrandAcceptance: .disallowed(brands: [.visa]))
        let cardSection = makeCardSectionElement(cardBrandFilter: filter)
        cardSection.panElement.setText(cbcVisaTestCard)
        XCTAssertEqual(cardSection.cardBrandChoiceElement?.selectedBrand, .cartesBancaires)
    }

    func testFiltering_noSelectionWhenMultipleBrandsAllowed() {
        let cardSection = makeCardSectionElement()
        cardSection.panElement.setText(cbcVisaTestCard)
        XCTAssertNil(cardSection.cardBrandChoiceElement?.selectedBrand)
    }

    func testFiltering_noSelectionWhenAllDisallowed() {
        let filter = CardBrandFilter(cardBrandAcceptance: .allowed(brands: [.mastercard]))
        let cardSection = makeCardSectionElement(cardBrandFilter: filter)
        cardSection.panElement.setText(cbcVisaTestCard)
        XCTAssertNil(cardSection.cardBrandChoiceElement?.selectedBrand)
    }

    // MARK: - Preferred networks + card brand filtering combined

    func testPreferredAndFiltering_fallsBackToDefaultWhenAllPreferredDisallowed() {
        let filter = CardBrandFilter(cardBrandAcceptance: .disallowed(brands: [.visa]))
        let cardSection = makeCardSectionElement(preferredNetworks: [.visa], cardBrandFilter: filter)
        cardSection.panElement.setText(cbcVisaTestCard)
        // Preferred brand is disallowed, falls back to default logic which autoselects the only allowed brand
        XCTAssertEqual(cardSection.cardBrandChoiceElement?.selectedBrand, .cartesBancaires)
    }
}
