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

    func testCanEditPaymentMethods_noPMs() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [],
                                                     cbcEligible: true)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }

    // MARK: - Single Card, cbcEligible
    func testCanEditPaymentMethods_singlePM_removeLast0_remove0() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                     cbcEligible: true)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singlePM_removeLast0_remove1() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                     cbcEligible: true)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singlePM_removeLast1_remove0() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                     cbcEligible: true)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singlePM_removeLast1_remove1() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                     cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: - Single Card, !cbcEligible
    func testCanEditPaymentMethods_singlePM_removeLast0_remove0_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                     cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singlePM_removeLast0_remove1_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                     cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singlePM_removeLast1_remove0_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                     cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singlePM_removeLast1_remove1_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                     cbcEligible: false)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: - Single Card, w/ Co-branded, cbcEligible
    func testCanEditPaymentMethods_singleCBCPM_removeLast0_remove0() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singleCBCPM_removeLast0_remove1() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singleCBCPM_removeLast1_remove0() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singleCBCPM_removeLast1_remove1() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    // MARK: - Single Card, w/ Co-branded, !cbcEligible
    func testCanEditPaymentMethods_singleCBCPM_removeLast0_remove0_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singleCBCPM_removeLast0_remove1_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singleCBCPM_removeLast1_remove0_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singleCBCPM_removeLast1_remove1_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: false)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: - Two Cards, cbcEligible
    func testCanEditPaymentMethods_TwoPM_removeLast0_remove0() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                     cbcEligible: true)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPM_removeLast0_remove1() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                     cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPM_removeLast1_remove0() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                     cbcEligible: true)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPM_removeLast1_remove1() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                     cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: - Two Cards, cbcEligible, !cbcEligible
    func testCanEditPaymentMethods_TwoPM_removeLast0_remove0_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                     cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPM_removeLast0_remove1_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                     cbcEligible: false)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPM_removeLast1_remove0_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                     cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPM_removeLast1_remove1_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                     cbcEligible: false)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: - Two Cards, w/ Co-branded, cbcEligible
    func testCanEditPaymentMethods_TwoPMCBC_removeLast0_remove0() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPMCBC_removeLast0_remove1() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPMCBC_removeLast1_remove0() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPMCBC_removeLast1_remove1() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: - Two Cards, w/ Co-branded, !cbcEligible
    func testCanEditPaymentMethods_TwoPMCBC_removeLast0_remove0_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPMCBC_removeLast0_remove1_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: false,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: false)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPMCBC_removeLast1_remove0_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: false)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPMCBC_removeLast1_remove1_notCBCEligible() {
        let configuration = configuration(allowsRemovalOfLastSavedPaymentMethod: true,
                                          paymentMethodRemove: true)
        let controller = customerSavedPaymentMethods(configuration,
                                                     savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                     cbcEligible: false)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    func configuration(allowsRemovalOfLastSavedPaymentMethod: Bool,
                       paymentMethodRemove: Bool) -> CustomerSavedPaymentMethodsCollectionViewController.Configuration {
        return CustomerSavedPaymentMethodsCollectionViewController.Configuration(showApplePay: false,
                                                                                 allowsRemovalOfLastSavedPaymentMethod: allowsRemovalOfLastSavedPaymentMethod,
                                                                                 paymentMethodRemove: paymentMethodRemove,
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
