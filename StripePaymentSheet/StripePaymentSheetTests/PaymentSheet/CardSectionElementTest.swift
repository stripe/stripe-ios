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
    // Mastercard test card that returns [.cartesBancaires, .mastercard]
    let cbcMastercardTestCard = "5555552500001001"

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

    /// Simulates a user tap on the currently selected brand, which is how a user attempts
    /// to deselect. Goes through the same `itemTapped` code path as a real tap.
    private func simulateTap(_ cardBrandChoice: CardBrandChoiceElement?, brand: STPCardBrand?) {
        guard case .selector(let element) = cardBrandChoice?.variant,
              let brand = brand else {
            XCTFail("Expected selector variant non-nil brand to tap")
            return
        }
        element.didTap(brand.makeCardBrandItem())
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

    func testPreferredNetwork_preventsDeselection() {
        let cardSection = makeCardSectionElement(preferredNetworks: [.cartesBancaires, .visa])
        cardSection.panElement.setText(cbcVisaTestCard)
        let cardBrandChoiceElement = cardSection.cardBrandChoiceElement
        XCTAssertEqual(cardBrandChoiceElement?.selectedBrand, .cartesBancaires)
        // Tapping the selected brand should not deselect it
        simulateTap(cardBrandChoiceElement, brand: cardBrandChoiceElement?.selectedBrand)
        XCTAssertEqual(cardSection.cardBrandChoiceElement?.selectedBrand, .cartesBancaires)
        // Tapping the other brand should be allowed
        simulateTap(cardBrandChoiceElement, brand: .visa)
        XCTAssertEqual(cardSection.cardBrandChoiceElement?.selectedBrand, .visa)
    }

    func testPreferredNetwork_reEnablesDeselectionWhenBrandsCleared() {
        let cardSection = makeCardSectionElement(preferredNetworks: [.visa])
        cardSection.panElement.setText(cbcVisaTestCard)
        let cardBrandChoiceElement = cardSection.cardBrandChoiceElement
        XCTAssertEqual(cardBrandChoiceElement?.selectedBrand, .visa)
        // Deselection is prevented after preferred-network autoselection
        simulateTap(cardBrandChoiceElement, brand: cardBrandChoiceElement?.selectedBrand)
        XCTAssertEqual(cardSection.cardBrandChoiceElement?.selectedBrand, .visa)

        // Reset
        cardSection.panElement.setText("")

        // Deselection should be allowed again
        cardSection.panElement.setText(cbcMastercardTestCard)
        XCTAssertNil(cardBrandChoiceElement?.selectedBrand)
        simulateTap(cardBrandChoiceElement, brand: .mastercard)
        XCTAssertEqual(cardSection.cardBrandChoiceElement?.selectedBrand, .mastercard)
        simulateTap(cardBrandChoiceElement, brand: .mastercard)
        XCTAssertNil(cardSection.cardBrandChoiceElement?.selectedBrand)
    }

    func testPreferredNetwork_noDeselectionPreventionWhenNoPreferredMatch() {
        let cardSection = makeCardSectionElement(preferredNetworks: [.mastercard])
        cardSection.panElement.setText(cbcVisaTestCard)
        XCTAssertNil(cardSection.cardBrandChoiceElement?.selectedBrand)
        // Manually select a brand, then verify deselection is allowed
        cardSection.cardBrandChoiceElement?.select(.cartesBancaires)
        XCTAssertEqual(cardSection.cardBrandChoiceElement?.selectedBrand, .cartesBancaires)
        simulateTap(cardSection.cardBrandChoiceElement, brand: .cartesBancaires)
        XCTAssertNil(cardSection.cardBrandChoiceElement?.selectedBrand)
    }

    // MARK: - Card brand filtering autoselection

    func testFiltering_autoselectsOnlyAllowedBrand() {
        let filter = CardBrandFilter(cardBrandAcceptance: .disallowed(brands: [.visa]))
        let cardSection = makeCardSectionElement(cardBrandFilter: filter)
        cardSection.panElement.setText(cbcVisaTestCard)
        XCTAssertEqual(cardSection.cardBrandChoiceElement?.selectedBrand, .cartesBancaires)
        XCTAssertFalse(cardSection.cardBrandChoiceElement?.view.isUserInteractionEnabled ?? true)
    }

    func testFiltering_noSelectionWhenMultipleBrandsAllowed() {
        let cardSection = makeCardSectionElement()
        cardSection.panElement.setText(cbcVisaTestCard)
        XCTAssertNil(cardSection.cardBrandChoiceElement?.selectedBrand)
        XCTAssertTrue(cardSection.cardBrandChoiceElement?.view.isUserInteractionEnabled ?? false)
    }

    func testFiltering_noSelectionWhenAllDisallowed() {
        let filter = CardBrandFilter(cardBrandAcceptance: .allowed(brands: [.mastercard]))
        let cardSection = makeCardSectionElement(cardBrandFilter: filter)
        cardSection.panElement.setText(cbcVisaTestCard)
        XCTAssertNil(cardSection.cardBrandChoiceElement?.selectedBrand)
        XCTAssertFalse(cardSection.cardBrandChoiceElement?.view.isUserInteractionEnabled ?? true)
    }

    // MARK: - Preferred networks + card brand filtering combined

    func testPreferredAndFiltering_fallsBackToDefaultWhenAllPreferredDisallowed() {
        let filter = CardBrandFilter(cardBrandAcceptance: .disallowed(brands: [.visa]))
        let cardSection = makeCardSectionElement(preferredNetworks: [.visa], cardBrandFilter: filter)
        cardSection.panElement.setText(cbcVisaTestCard)
        // Preferred brand is disallowed, falls back to default logic which autoselects the only allowed brand
        XCTAssertEqual(cardSection.cardBrandChoiceElement?.selectedBrand, .cartesBancaires)
    }

    // MARK: - CBC Tooltip visibility

    /// Places the card section view in a window so that `becomeFirstResponder()` works,
    /// and begins editing the PAN field.
    @discardableResult
    private func beginEditingPAN(_ cardSection: CardSectionElement) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.addSubview(cardSection.view)
        window.makeKeyAndVisible()
        cardSection.view.layoutIfNeeded()
        _ = cardSection.panElement.textFieldView.textField.becomeFirstResponder()
        return window
    }

    func testTooltip_showsWhenEditingWithMultipleBrands() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        let cardSection = makeCardSectionElement()
        _ = beginEditingPAN(cardSection)

        cardSection.panElement.setText(cbcVisaTestCard)

        XCTAssertNotNil(cardSection.cbcTooltip.superview)
        XCTAssertEqual(cardSection.cbcTooltip.alpha, 1)
    }

    func testTooltip_hidesWhenNotEditing() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        let cardSection = makeCardSectionElement()

        // Set CBC card without making PAN field first responder
        cardSection.panElement.setText(cbcVisaTestCard)

        XCTAssertEqual(cardSection.cbcTooltip.alpha, 0)
    }

    func testTooltip_hidesAfterBrandSelected() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        let cardSection = makeCardSectionElement()
        _ = beginEditingPAN(cardSection)

        cardSection.panElement.setText(cbcVisaTestCard)
        XCTAssertEqual(cardSection.cbcTooltip.alpha, 1)

        _ = cardSection.expiryElement.textFieldView.textField.becomeFirstResponder()

        XCTAssertEqual(cardSection.cbcTooltip.alpha, 0)
    }

    func testTooltip_hidesAfterFocusChanged() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        let cardSection = makeCardSectionElement()
        _ = beginEditingPAN(cardSection)

        cardSection.panElement.setText(cbcVisaTestCard)
        XCTAssertEqual(cardSection.cbcTooltip.alpha, 1)

        cardSection.cardBrandChoiceElement?.select(.visa)
        cardSection.didUpdate(element: cardSection.panElement)

        XCTAssertEqual(cardSection.cbcTooltip.alpha, 0)
    }

    func testTooltip_reappearsAfterBrandsReset() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        let cardSection = makeCardSectionElement()
        _ = beginEditingPAN(cardSection)

        cardSection.panElement.setText(cbcVisaTestCard)
        cardSection.cardBrandChoiceElement?.select(.visa)
        cardSection.didUpdate(element: cardSection.panElement)
        XCTAssertEqual(cardSection.cbcTooltip.alpha, 0)

        // Clear PAN to reset brands and the hasBrandBeenSelected latch
        cardSection.panElement.setText("")
        // Re-enter CBC card — tooltip should reappear
        cardSection.panElement.setText(cbcVisaTestCard)

        XCTAssertEqual(cardSection.cbcTooltip.alpha, 1)
    }

    func testTooltip_hiddenWhenAllDisabled() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        let filter = CardBrandFilter(cardBrandAcceptance: .allowed(brands: [.mastercard]))
        let cardSection = makeCardSectionElement(cardBrandFilter: filter)
        _ = beginEditingPAN(cardSection)

        cardSection.panElement.setText(cbcVisaTestCard)
        XCTAssertEqual(cardSection.cbcTooltip.alpha, 0)
    }
}
