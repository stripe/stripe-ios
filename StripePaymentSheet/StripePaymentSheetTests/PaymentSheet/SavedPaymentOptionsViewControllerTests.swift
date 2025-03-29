//
//  SavedPaymentOptionsViewControllerTests.swift
//  StripePaymentSheetTests
//

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
