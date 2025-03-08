//
//  STPPaymentMethod+PaymentSheetTests.swift
//  StripePaymentSheet
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore
import XCTest

class STPPPaymentMethodPaymentSheetTests: XCTestCase {
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
    }
    func _testHasUpdatedAutomaticBillingDetailsParam(_ paymentMethod: STPPaymentMethod, postalCode: String, country: String) -> Bool {
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
}
