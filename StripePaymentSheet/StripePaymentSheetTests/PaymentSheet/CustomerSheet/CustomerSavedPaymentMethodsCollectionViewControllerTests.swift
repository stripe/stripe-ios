//
//  CustomerSavedPaymentMethodsCollectionViewControllerTests.swift
//  StripePaymentSheetTests
//

@testable import StripePaymentSheet
import XCTest

class CustomerSavedPaymentMethodsCollectionViewControllerTests: XCTestCase {
    var customerSheetConfiguration: CustomerSheet.Configuration = {
        return CustomerSheet.Configuration()
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

        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))

        // Skip where removePM = false && removeLastPM = true

        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard()]))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard()]))
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

        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))

        // Skip where removePM = false && removeLastPM = true

        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertTrue(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: false, updatePM: true, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: true, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()]))
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

        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: true, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()]))
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

        XCTAssertFalse(_testCanEditPaymentMethods(removePM: false, removeLastPM: false, defaultPM: true, updatePM: false, cbcEligible: false, savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()]))
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

    func testHideNonCardUSBank_SetAsDefault() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: true,
                                          paymentMethodUpdate: false,
                                          paymentMethodSyncDefault: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testUSBankAccount(), STPPaymentMethod._testSEPA()],
                                                     cbcEligible: false)
        XCTAssertFalse(controller.savedPaymentMethods.contains(where: { $0.type == .SEPADebit }))
    }

    func _testCanEditPaymentMethods(removePM: Bool,
                                    removeLastPM: Bool,
                                    defaultPM: Bool,
                                    updatePM: Bool,
                                    cbcEligible: Bool,
                                    savedPaymentMethods: [STPPaymentMethod]) -> Bool {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: removeLastPM,
                                          paymentMethodRemove: removePM,
                                          paymentMethodUpdate: updatePM,
                                          paymentMethodSyncDefault: defaultPM)
        let controller = customerSavedPaymentMethods(configuration, savedPaymentMethods: savedPaymentMethods, cbcEligible: cbcEligible)
        return controller.canEditPaymentMethods
    }

    func configuration(allowsRemovalOfLastSavedPaymentMethod: Bool,
                       paymentMethodRemove: Bool,
                       paymentMethodUpdate: Bool,
                       paymentMethodSyncDefault: Bool
    ) -> CustomerSavedPaymentMethodsCollectionViewController.Configuration {

        let billingDetailsCollectionConfiguration = PaymentSheet.BillingDetailsCollectionConfiguration(name: .never,
                                                                                                       phone: .never,
                                                                                                       email: .never,
                                                                                                       address: .never)
        return CustomerSavedPaymentMethodsCollectionViewController.Configuration(billingDetailsCollectionConfiguration: billingDetailsCollectionConfiguration,
                                                                                 showApplePay: false,
                                                                                 allowsRemovalOfLastSavedPaymentMethod: allowsRemovalOfLastSavedPaymentMethod,
                                                                                 paymentMethodRemove: paymentMethodRemove,
                                                                                 paymentMethodRemoveIsPartial: false,
                                                                                 paymentMethodUpdate: paymentMethodUpdate,
                                                                                 paymentMethodSyncDefault: paymentMethodSyncDefault,
                                                                                 isTestMode: true)
    }
    func customerSavedPaymentMethods(_ configuration: CustomerSavedPaymentMethodsCollectionViewController.Configuration,
                                     savedPaymentMethods: [STPPaymentMethod],
                                     cbcEligible: Bool) -> CustomerSavedPaymentMethodsCollectionViewController {
        return CustomerSavedPaymentMethodsCollectionViewController(savedPaymentMethods: savedPaymentMethods,
                                                                   selectedPaymentMethodOption: nil,
                                                                   mostRecentlyAddedPaymentMethod: nil,
                                                                   savedPaymentMethodsConfiguration: customerSheetConfiguration,
                                                                   configuration: configuration,
                                                                   appearance: .default,
                                                                   cbcEligible: cbcEligible, delegate: nil)
    }
}
