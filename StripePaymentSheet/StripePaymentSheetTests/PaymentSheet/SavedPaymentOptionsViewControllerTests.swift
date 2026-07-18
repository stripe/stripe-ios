//
//  SavedPaymentOptionsViewControllerTests.swift
//  StripePaymentSheetTests
//

@_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

class SavedPaymentOptionsViewControllerTests: XCTestCase {

    lazy var paymentSheetConfiguration: PaymentSheet.Configuration = {
        return PaymentSheet.Configuration._testValue_MostPermissive()
    }()

    func testNoPM() {
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: []))

        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: []))

        // Skip where removePM == false && removeLastPM == true

        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: []))

        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: []))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: []))
    }
    func testSinglePM_nonCoBranded() {
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))

        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))

        // Skip where removePM = false && removeLastPM = true

        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))

        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))
    }

    func testSinglePM_coBranded() {
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))

        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))

        // Skip where removePM = false && removeLastPM = true

        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))

        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
    }
    func testTwoPMs_nonCoBranded() {
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))

        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))

        // Skip where removePM = false && removeLastPM = true

        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))

        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))

    }

    func testTwoPMs_coBranded() {
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))

        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))

        // Skip where removePM = false && removeLastPM = true

        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))

        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: true, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
    }

    // Test case for when the preferred brand of a card is nil that we look at the display brand
    func testRemovalMessagePreferredBrand_nilPreferredBrand() {
        let coBrandedCard = STPPaymentMethod._testCardCoBranded(displayBrand: "cartes_bancaires")
        XCTAssertNil(coBrandedCard.card?.networks?.preferred)
        let removalMessage = coBrandedCard.removalMessage

        XCTAssertEqual(removalMessage.message, "Cartes Bancaires •••• 4242")
    }

    func testRemovalMessage_LinkGenericPaymentMethod() {
        let paymentMethod = STPPaymentMethod._testLink()
        paymentMethod.linkPaymentDetails = .generic(
            LinkPaymentDetails.Generic(
                id: "csmrpd_123",
                label: "Pix",
                sublabel: "000••••••••"
            )
        )

        let removalMessage = paymentMethod.removalMessage

        XCTAssertEqual(removalMessage.title, "Remove payment method?")
        XCTAssertEqual(removalMessage.message, "Pix 000••••••••")
    }

    func testPaymentOptionCell_usesProvidedLinkBrandForLinkLabel() {
        let cell = SavedPaymentMethodCollectionView.PaymentOptionCell(frame: .zero)

        cell.setViewModel(
            .link,
            cbcEligible: false,
            allowsPaymentMethodRemoval: false,
            allowsPaymentMethodUpdate: false,
            linkBrand: .onelink
        )

        XCTAssertEqual(cell.label.text, "Onelink")
        XCTAssertEqual(cell.selectableRectangle.accessibilityLabel, "One-link")
    }

    func testSetSelectionSelectsAvailableOptionsWithoutPersisting() throws {
        // Given a persisted card and a carousel with wallet and saved options
        let customerID = "cus_set_selection"
        let firstPaymentMethod = STPPaymentMethod._testCard()
        let secondPaymentMethod = STPPaymentMethod._testUSBankAccount()
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(firstPaymentMethod.stripeId), forCustomer: customerID)
        defer {
            CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID)
        }
        let controller = makeViewController(
            savedPaymentMethods: [firstPaymentMethod, secondPaymentMethod],
            customerID: customerID
        )

        // When each available option is selected programmatically
        controller.setSelection(to: .applePay)
        guard case .applePay = controller.selectedPaymentOption else {
            return XCTFail("Expected Apple Pay to be selected")
        }

        controller.setSelection(to: .link(option: .wallet(brand: .link)))
        guard case .link = controller.selectedPaymentOption else {
            return XCTFail("Expected Link to be selected")
        }

        controller.setSelection(to: .saved(paymentMethod: secondPaymentMethod, confirmParams: nil))
        let selectedPaymentMethod = try XCTUnwrap(controller.selectedPaymentOption?.savedPaymentMethod)

        // Then the carousel reflects the selection without changing persistence
        XCTAssertEqual(selectedPaymentMethod.stripeId, secondPaymentMethod.stripeId)
        XCTAssertEqual(
            CustomerPaymentOption.localDefaultPaymentMethod(for: customerID),
            .stripeId(firstPaymentMethod.stripeId)
        )
    }

    func testSetSelectionIgnoresOptionsOutsideTheCarousel() throws {
        // Given a selected saved method
        let card = STPPaymentMethod._testCard()
        let unavailablePaymentMethod = STPPaymentMethod._testUSBankAccount()
        let controller = makeViewController(savedPaymentMethods: [card])
        controller.setSelection(to: .saved(paymentMethod: card, confirmParams: nil))

        // When asked to select an unavailable saved method or a form-backed option
        controller.setSelection(to: .saved(paymentMethod: unavailablePaymentMethod, confirmParams: nil))
        controller.setSelection(to: .new(confirmParams: IntentConfirmParams(type: .stripe(.card))))

        // Then the existing carousel selection is unchanged
        let selectedPaymentMethod = try XCTUnwrap(controller.selectedPaymentOption?.savedPaymentMethod)
        XCTAssertEqual(selectedPaymentMethod.stripeId, card.stripeId)
    }

    // MARK: Helpers

    private func makeViewController(
        savedPaymentMethods: [STPPaymentMethod],
        customerID: String = "cus_saved_payment_options"
    ) -> SavedPaymentOptionsViewController {
        let configuration = SavedPaymentOptionsViewController.Configuration(
            customerID: customerID,
            showApplePay: true,
            showLink: true,
            linkBrand: .link,
            removeSavedPaymentMethodMessage: nil,
            merchantDisplayName: "Test Merchant",
            isCVCRecollectionEnabled: false,
            isTestMode: true,
            allowsRemovalOfLastSavedPaymentMethod: true,
            allowsRemovalOfPaymentMethods: true,
            allowsSetAsDefaultPM: false,
            allowsUpdatePaymentMethod: false
        )
        return SavedPaymentOptionsViewController(
            savedPaymentMethods: savedPaymentMethods,
            configuration: configuration,
            paymentSheetConfiguration: paymentSheetConfiguration,
            intent: Intent._testValue(),
            appearance: .default,
            elementsSession: .emptyElementsSession,
            analyticsHelper: ._testValue()
        )
    }

    func _testCanEditPaymentMethods(removePM: Bool,
                                    removeLastPM: Bool,
                                    defaultPM: Bool,
                                    updatePM: Bool,
                                    cbcEligible: Bool,
                                    savedPaymentMethods: [STPPaymentMethod]) -> Bool {
        let configuration = SavedPaymentOptionsViewController.Configuration(customerID: "cus_123",
                                                                            showApplePay: true,
                                                                            showLink: true,
                                                                            linkBrand: .link,
                                                                            removeSavedPaymentMethodMessage: nil,
                                                                            merchantDisplayName: "abc",
                                                                            isCVCRecollectionEnabled: true,
                                                                            isTestMode: true,
                                                                            allowsRemovalOfLastSavedPaymentMethod: removeLastPM,
                                                                            allowsRemovalOfPaymentMethods: removePM,
                                                                            allowsSetAsDefaultPM: defaultPM,
                                                                            allowsUpdatePaymentMethod: updatePM)
        let controller = SavedPaymentOptionsViewController(savedPaymentMethods: savedPaymentMethods,
                                                           configuration: configuration,
                                                           paymentSheetConfiguration: paymentSheetConfiguration,
                                                           intent: Intent._testValue(),
                                                           appearance: .default,
                                                           elementsSession: .emptyElementsSession,
                                                           cbcEligible: cbcEligible,
                                                           analyticsHelper: ._testValue(),
                                                           delegate: nil)
        return controller.canEditPaymentMethods
    }
}
