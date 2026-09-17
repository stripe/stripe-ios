//
//  STPPaymentMethod+PaymentSheetTests.swift
//  StripePaymentSheet
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore
import XCTest

class STPPPaymentMethodPaymentSheetTests: XCTestCase {
    func testLinkGenericFormattedDisplayText() {
        let genericDetails = LinkPaymentDetails.Generic(
            id: "csmrpd_123",
            label: "Pix",
            sublabel: "000••••••••"
        )

        XCTAssertEqual(genericDetails.formattedDisplayText, "Pix 000••••••••")
        XCTAssertEqual(LinkPaymentDetails.generic(genericDetails).formattedLast4, "Pix 000••••••••")

        let paymentMethod = STPPaymentMethod._testLink()
        paymentMethod.linkPaymentDetails = .generic(genericDetails)
        XCTAssertEqual(paymentMethod.linkPaymentDetailsFormattedString, "Pix 000••••••••")
    }

    func testIsLinkPassthroughMode() {
        let plainCard = STPPaymentMethod._testCard()
        XCTAssertFalse(plainCard.isLinkPassthroughMode)

        let linkOriginCard = STPPaymentMethod._testCard()
        linkOriginCard.isLinkOrigin = true
        XCTAssertTrue(linkOriginCard.isLinkPassthroughMode)

        let linkWalletCard = makeLinkWalletCardPaymentMethod()
        XCTAssertTrue(linkWalletCard.isLinkPassthroughMode)
        XCTAssertFalse(linkWalletCard.isLinkOrigin)
        XCTAssertFalse(linkWalletCard.isLinkPaymentMethod)

        let linkPaymentMethod = STPPaymentMethod._testLink()
        XCTAssertTrue(linkPaymentMethod.isLinkPaymentMethod)
        XCTAssertFalse(linkPaymentMethod.isLinkPassthroughMode)
    }

    func testUpdateLocalFields_preservesLinkPresentationState() {
        let originalPaymentMethod = STPPaymentMethod._testCard()
        originalPaymentMethod.linkPaymentDetails = .card(
            LinkPaymentDetails.Card(
                id: "csmrpd_123",
                displayName: "Visa",
                expMonth: 12,
                expYear: 2030,
                last4: "4242",
                brand: .visa
            )
        )
        originalPaymentMethod.isLinkOrigin = true

        let updatedPaymentMethod = STPPaymentMethod.stubbedPaymentMethod()
        XCTAssertNil(updatedPaymentMethod.linkPaymentDetails)
        XCTAssertFalse(updatedPaymentMethod.isLinkOrigin)

        updatedPaymentMethod.updateLocalFields(from: originalPaymentMethod)

        XCTAssertEqual(updatedPaymentMethod.linkPaymentDetailsFormattedString, originalPaymentMethod.linkPaymentDetailsFormattedString)
        XCTAssertTrue(updatedPaymentMethod.isLinkOrigin)
    }

    func testUpdateLocalFields_preservesCardArt() {
        // Given a card with card art (only returned by v1/elements/sessions)...
        let originalPaymentMethod = STPPaymentMethod._testCardWithCardArt()
        XCTAssertEqual(originalPaymentMethod.cardArtProgramName, "Test Program")

        // ...and an updated card from the update endpoint, which has no card art
        let updatedPaymentMethod = STPPaymentMethod._testCard()
        XCTAssertNil(updatedPaymentMethod.card?.cardArt)

        // When the local fields are carried over
        updatedPaymentMethod.updateLocalFields(from: originalPaymentMethod)

        // Then the card art, and therefore the program name, survives the update
        XCTAssertEqual(updatedPaymentMethod.card?.cardArt?.artImage?.url, originalPaymentMethod.card?.cardArt?.artImage?.url)
        XCTAssertEqual(updatedPaymentMethod.cardArtProgramName, "Test Program")
    }

    // MARK: - cardArtProgramName

    func testCardArtProgramName_returnsProgramName() {
        // Given a card with both card art and a program name
        let paymentMethod = STPPaymentMethod._testCardWithCardArt()

        // Then the program name is returned
        XCTAssertEqual(paymentMethod.cardArtProgramName, "Test Program")
    }

    func testCardArtProgramName_isNilWithoutCardArt() {
        // Given a card with no card art at all
        let paymentMethod = STPPaymentMethod._testCard()

        // Then there is no program name
        XCTAssertNil(paymentMethod.cardArtProgramName)
    }

    func testCardArtProgramName_isNilWithoutArtImage() {
        // Given a card whose card art has a program name but no art image...
        let paymentMethod = STPPaymentMethod._testCard()
        paymentMethod.card?.cardArt = STPPaymentMethodCardArt.decodedObject(fromAPIResponse: [
            "program_name": "Test Program",
        ])

        // Then there is no program name, since program names are only shown alongside card art
        XCTAssertNil(paymentMethod.cardArtProgramName)
    }

    func testCardArtProgramName_isNilWhenProgramNameMissing() {
        // Given a card whose card art has an art image but no program name
        let paymentMethod = STPPaymentMethod._testCard()
        paymentMethod.card?.cardArt = STPPaymentMethodCardArt.decodedObject(fromAPIResponse: [
            "art_image": ["url": "https://example.com/art.png"],
        ])

        XCTAssertNil(paymentMethod.cardArtProgramName)
    }

    func testCardArtProgramName_isNilWhenProgramNameIsEmpty() {
        // Given a card whose card art has an empty program name
        let paymentMethod = STPPaymentMethod._testCard()
        paymentMethod.card?.cardArt = STPPaymentMethodCardArt.decodedObject(fromAPIResponse: [
            "art_image": ["url": "https://example.com/art.png"],
            "program_name": "",
        ])

        XCTAssertNil(paymentMethod.cardArtProgramName)
    }

    func testHasUpdatedCardParams() {
        XCTAssertFalse(_testHasUpdatedCardParams(STPPaymentMethod._testCard(), expMonth: 01, expYear: 40))
        XCTAssertTrue(_testHasUpdatedCardParams(STPPaymentMethod._testCard(), expMonth: 01, expYear: 41))
        XCTAssertTrue(_testHasUpdatedCardParams(STPPaymentMethod._testCard(), expMonth: 02, expYear: 40))
        XCTAssertTrue(_testHasUpdatedCardParams(STPPaymentMethod._testCard(), expMonth: 02, expYear: 41))
        XCTAssertFalse(_testHasUpdatedCardParams(STPPaymentMethod._testUSBankAccount(), expMonth: 02, expYear: 41))
    }
    func _testHasUpdatedCardParams(_ paymentMethod: STPPaymentMethod, expMonth: NSNumber, expYear: NSNumber) -> Bool {
        let updatedParams = STPPaymentMethodCardParams()
        updatedParams.expMonth = expMonth
        updatedParams.expYear = expYear

        return paymentMethod.hasUpdatedCardParams(updatedParams)
    }
    func testHasUpdatedCardParams_nil() {
        let cardPaymentMethod = STPPaymentMethod._testCard()
        XCTAssertFalse(cardPaymentMethod.hasUpdatedCardParams(nil))
    }

    func testHasUpdatedAutomaticBillingDetailsParams() {
        XCTAssertFalse(_testHasUpdatedAutomaticBillingDetailsParam(STPPaymentMethod._testCard(postalCode: "12345", countryCode: "US"), postalCode: "12345", country: "US"))
        XCTAssertTrue(_testHasUpdatedAutomaticBillingDetailsParam(STPPaymentMethod._testCard(postalCode: "12345", countryCode: "US"), postalCode: "12344", country: "US"))
        XCTAssertTrue(_testHasUpdatedAutomaticBillingDetailsParam(STPPaymentMethod._testCard(postalCode: "12345", countryCode: "US"), postalCode: "12345", country: "GB"))
        XCTAssertTrue(_testHasUpdatedAutomaticBillingDetailsParam(STPPaymentMethod._testCard(postalCode: "12345", countryCode: "US"), postalCode: "12344", country: "GB"))
        XCTAssertTrue(_testHasUpdatedAutomaticBillingDetailsParam(STPPaymentMethod._testCard(), postalCode: "12344", country: "GB"))
        XCTAssertFalse(_testHasUpdatedAutomaticBillingDetailsParam(STPPaymentMethod._testCard(postalCode: "12345", countryCode: "FR"), postalCode: nil, country: "FR"))
    }
    func _testHasUpdatedAutomaticBillingDetailsParam(_ paymentMethod: STPPaymentMethod, postalCode: String?, country: String) -> Bool {
        let updatedParams = STPPaymentMethodBillingDetails()
        updatedParams.nonnil_address.postalCode = postalCode
        updatedParams.nonnil_address.country = country

        return paymentMethod.hasUpdatedAutomaticBillingDetailsParams(updatedParams)
    }
    func testHasUpdatedAutomaticBillingDetailsParams_nilParams() {
        let cardPaymentMethod = STPPaymentMethod._testCard(postalCode: "12345", countryCode: "US")
        XCTAssertFalse(cardPaymentMethod.hasUpdatedAutomaticBillingDetailsParams(nil))
    }

    func testHasUpdatedFullBillingDetailsParams_nilLine2() {
        let cardWithFullAddr = STPPaymentMethod._testCard(line1: "123 main",
                                                          line2: nil,
                                                          city: "San Francisco",
                                                          state: "CA",
                                                          postalCode: "94016",
                                                          countryCode: "US")
        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "1234 main", line2: "apt 2", city: "San Francisco", state: "CA", postalCode: "94016", country: "US"))

        XCTAssertFalse(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: nil, city: "San Francisco", state: "CA", postalCode: "94016", country: "US"))
        XCTAssertFalse(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: "", city: "San Francisco", state: "CA", postalCode: "94016", country: "US"))
        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: "apt 2", city: "San Francisco", state: "CA", postalCode: "94016", country: "US"))

        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: "", city: "Los Angeles", state: "CA", postalCode: "94016", country: "US"))
        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: "", city: "San Francisco", state: "WA", postalCode: "94016", country: "US"))
        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: "", city: "San Francisco", state: "CA", postalCode: "12345", country: "US"))
        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: "", city: "San Francisco", state: "CA", postalCode: "94016", country: "GB"))
        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: STPPaymentMethod._testCard(), line1: "123 main", line2: "", city: "San Francisco", state: "CA", postalCode: "94016", country: "GB"))
    }

    func testHasUpdatedFullBillingDetailsParams_withLine2() {
        let cardWithFullAddr = STPPaymentMethod._testCard(line1: "123 main",
                                                          line2: "apt 2",
                                                          city: "San Francisco",
                                                          state: "CA",
                                                          postalCode: "94016",
                                                          countryCode: "US")
        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "1234 main", line2: "apt 2", city: "San Francisco", state: "CA", postalCode: "94016", country: "US"))

        XCTAssertFalse(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: "apt 2", city: "San Francisco", state: "CA", postalCode: "94016", country: "US"))
        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: "", city: "San Francisco", state: "CA", postalCode: "94016", country: "US"))
        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: nil, city: "San Francisco", state: "CA", postalCode: "94016", country: "US"))

        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: "apt 2", city: "Los Angeles", state: "CA", postalCode: "94016", country: "US"))
        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: "apt 2", city: "San Francisco", state: "WA", postalCode: "94016", country: "US"))
        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: "apt 2", city: "San Francisco", state: "CA", postalCode: "12345", country: "US"))
        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: "apt 2", city: "San Francisco", state: "CA", postalCode: "94016", country: "GB"))
        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: STPPaymentMethod._testCard(), line1: "123 main", line2: "apt 2", city: "San Francisco", state: "CA", postalCode: "94016", country: "GB"))
    }

    func testHasUpdatedFullBillingDetailsParams_nil() {
        let cardWithFullAddr = STPPaymentMethod._testCard(line1: "123 main",
                                                          line2: "apt 2",
                                                          city: "San Francisco",
                                                          state: "CA",
                                                          postalCode: "94016",
                                                          countryCode: "US")
        XCTAssertFalse(cardWithFullAddr.hasUpdatedFullBillingDetailsParams(nil))
    }

    func _testHasUpdatedFullBillingDetailsParams(paymentMethod: STPPaymentMethod, line1: String, line2: String?, city: String, state: String, postalCode: String, country: String) -> Bool {
        let updatedParams = STPPaymentMethodBillingDetails()
        updatedParams.nonnil_address.line1 = line1
        updatedParams.nonnil_address.line2 = line2
        updatedParams.nonnil_address.city = city
        updatedParams.nonnil_address.state = state
        updatedParams.nonnil_address.postalCode = postalCode
        updatedParams.nonnil_address.country = country

        return paymentMethod.hasUpdatedFullBillingDetailsParams(updatedParams)
    }
    func testHasUpdatedFullBillingDetailsParams_full_to_another() {
        let cardWithFullAddr = STPPaymentMethod._testCard(line1: "123 main",
                                                          line2: nil,
                                                          city: "San Francisco",
                                                          state: "CA",
                                                          postalCode: "94016",
                                                          countryCode: "US")
        XCTAssertFalse(_testHasUpdatedAutomaticBillingDetailsParam(cardWithFullAddr, postalCode: "94016", country: "US"))
        XCTAssertTrue(_testHasUpdatedAutomaticBillingDetailsParam(cardWithFullAddr, postalCode: "12345", country: "US"))

        XCTAssertFalse(_testHasUpdatedAutomaticBillingDetailsParam(cardWithFullAddr, postalCode: "94016", country: "US"))
        XCTAssertTrue(_testHasUpdatedAutomaticBillingDetailsParam(cardWithFullAddr, postalCode: "12345", country: "US"))
    }
    func testHasUpdatedFullBillingDetailsParams_auto_to_full() {
        let cardWithFullAddr = STPPaymentMethod._testCard(postalCode: "94016",
                                                          countryCode: "US")

        let updatedParams = STPPaymentMethodBillingDetails()
        updatedParams.nonnil_address.line1 = "123 main"
        updatedParams.nonnil_address.line2 = "apt 2"
        updatedParams.nonnil_address.city = "San Francisco"
        updatedParams.nonnil_address.state = "CA"
        updatedParams.nonnil_address.postalCode = "94016"
        updatedParams.nonnil_address.country = "US"

        XCTAssertTrue(_testHasUpdatedFullBillingDetailsParams(paymentMethod: cardWithFullAddr, line1: "123 main", line2: "apt 2", city: "San Francisco", state: "CA", postalCode: "94016", country: "US"))
    }

    private func makeLinkWalletCardPaymentMethod() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_link_wallet_card",
            "object": "payment_method",
            "created": "12345",
            "type": "card",
            "card": [
                "brand": "visa",
                "last4": "4242",
                "exp_month": 12,
                "exp_year": 2025,
                "wallet": [
                    "type": "link",
                ],
            ],
        ])!
    }
}
