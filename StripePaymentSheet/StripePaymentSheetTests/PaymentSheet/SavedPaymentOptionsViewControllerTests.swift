//
//  SavedPaymentOptionsViewControllerTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
@_spi(STP) import StripePayments
@testable import StripePaymentSheet
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

    func testPaymentOptionCell_rightToLeftVoiceOverTraversalReadsPaymentMethodBeforeEdit() throws {
        let cell = SavedPaymentMethodCollectionView.PaymentOptionCell(
            frame: CGRect(x: 0, y: 0, width: 106, height: 112)
        )
        cell.setViewModel(
            .saved(paymentMethod: STPPaymentMethod._testCard()),
            cbcEligible: false,
            allowsPaymentMethodRemoval: true,
            allowsPaymentMethodUpdate: true
        )
        cell.isRemovingPaymentMethods = true
        cell.semanticContentAttribute = .forceRightToLeft
        cell.layoutIfNeeded()

        let accessibilityElements = try XCTUnwrap(cell.accessibilityElements as? [UIView])
        XCTAssertTrue(accessibilityElements[0] === cell.selectableRectangle)
        XCTAssertTrue(accessibilityElements[1] === cell.accessoryButton)
        XCTAssertLessThan(cell.accessoryButton.frame.midX, cell.selectableRectangle.frame.midX)
    }

    func testSavedPaymentMethods_rightToLeftOverflowRendersFirstItemAtLeadingEdge() throws {
        // Given an overflowing saved payment method carousel in a right-to-left interface
        let configuration = SavedPaymentOptionsViewController.Configuration(
            customerID: "cus_123",
            showApplePay: true,
            showLink: true,
            linkBrand: .link,
            removeSavedPaymentMethodMessage: nil,
            merchantDisplayName: "Test Merchant",
            isCVCRecollectionEnabled: false,
            isTestMode: false,
            allowsRemovalOfLastSavedPaymentMethod: false,
            allowsRemovalOfPaymentMethods: true,
            allowsSetAsDefaultPM: false,
            allowsUpdatePaymentMethod: false
        )
        let sut = SavedPaymentOptionsViewController(
            savedPaymentMethods: [
                STPPaymentMethod._testCard(),
                STPPaymentMethod._testUSBankAccount(),
                STPPaymentMethod._testSEPA(),
            ],
            configuration: configuration,
            paymentSheetConfiguration: paymentSheetConfiguration,
            intent: Intent._testValue(),
            appearance: .default,
            elementsSession: .emptyElementsSession,
            analyticsHelper: ._testValue()
        )
        let hostViewController = UIViewController()
        hostViewController.addChild(sut)
        hostViewController.setOverrideTraitCollection(
            UITraitCollection(layoutDirection: .rightToLeft),
            forChild: sut
        )
        hostViewController.view.addSubview(sut.view)
        sut.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sut.view.topAnchor.constraint(equalTo: hostViewController.view.topAnchor),
            sut.view.leadingAnchor.constraint(equalTo: hostViewController.view.leadingAnchor),
            sut.view.trailingAnchor.constraint(equalTo: hostViewController.view.trailingAnchor),
            sut.view.bottomAnchor.constraint(equalTo: hostViewController.view.bottomAnchor),
        ])
        sut.didMove(toParent: hostViewController)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
        window.rootViewController = hostViewController
        window.isHidden = false

        // When the carousel is laid out
        hostViewController.view.layoutIfNeeded()
        sut.collectionView.layoutIfNeeded()

        // Then item zero is first in reading order and visible at the physical right edge
        let firstItem = try XCTUnwrap(
            sut.collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
        )
        let secondItem = try XCTUnwrap(
            sut.collectionView.cellForItem(at: IndexPath(item: 1, section: 0))
        )
        let firstItemFrame = firstItem.convert(firstItem.bounds, to: window)
        let secondItemFrame = secondItem.convert(secondItem.bounds, to: window)
        let visibleCollectionFrame = sut.collectionView.convert(sut.collectionView.bounds, to: window)
        XCTAssertEqual(sut.collectionView.effectiveUserInterfaceLayoutDirection, .rightToLeft)
        XCTAssertGreaterThan(firstItemFrame.midX, secondItemFrame.midX)
        XCTAssertTrue(visibleCollectionFrame.contains(firstItemFrame))
        XCTAssertEqual(
            visibleCollectionFrame.maxX - firstItemFrame.maxX,
            PaymentSheet.Appearance.default.formInsets.leading,
            accuracy: 1
        )
        withExtendedLifetime(window) {}
    }

    // MARK: Helpers
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
