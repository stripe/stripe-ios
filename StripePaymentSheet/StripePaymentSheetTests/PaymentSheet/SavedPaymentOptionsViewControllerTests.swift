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

    func testCanEditPaymentMethods_noPMs() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [],
                                                       cbcEligible: true)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }

    // MARK: - Single Card, cbcEligible
    func testCanEditPaymentMethods_singlePM_removeLast0_remove0() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                       cbcEligible: true)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singlePM_removeLast0_remove1() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                       cbcEligible: true)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singlePM_removeLast1_remove0() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                       cbcEligible: true)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singlePM_removeLast1_remove1() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                       cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: - Single Card, !cbcEligible
    func testCanEditPaymentMethods_singlePM_removeLast0_remove0_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                       cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singlePM_removeLast0_remove1_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                       cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singlePM_removeLast1_remove0_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                       cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singlePM_removeLast1_remove1_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard()],
                                                       cbcEligible: false)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: - Single Card, w/ Co-branded, cbcEligible
    func testCanEditPaymentMethods_singleCBCPM_removeLast0_remove0() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singleCBCPM_removeLast0_remove1() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singleCBCPM_removeLast1_remove0() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singleCBCPM_removeLast1_remove1() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: - Single Card, w/ Co-branded, !cbcEligible
    func testCanEditPaymentMethods_singleCBCPM_removeLast0_remove0_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singleCBCPM_removeLast0_remove1_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singleCBCPM_removeLast1_remove0_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_singleCBCPM_removeLast1_remove1_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: false)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: - Two Cards, cbcEligible
    func testCanEditPaymentMethods_TwoPM_removeLast0_remove0() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                       cbcEligible: true)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPM_removeLast0_remove1() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                       cbcEligible: true)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPM_removeLast1_remove0() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                       cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPM_removeLast1_remove1() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                       cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: - Two Cards, !cbcEligible
    func testCanEditPaymentMethods_TwoPM_removeLast0_remove0_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                       cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPM_removeLast0_remove1_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                       cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPM_removeLast1_remove0_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                       cbcEligible: false)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPM_removeLast1_remove1_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardAmex()],
                                                       cbcEligible: false)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: - Two Cards, w/ Co-branded, cbcEligible
    func testCanEditPaymentMethods_TwoPMCBC_removeLast0_remove0() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPMCBC_removeLast0_remove1() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPMCBC_removeLast1_remove0() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPMCBC_removeLast1_remove1() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: true)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: - Two Cards, w/ Co-branded, !cbcEligible
    func testCanEditPaymentMethods_TwoPMCBC_removeLast0_remove0_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPMCBC_removeLast0_remove1_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: false)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: false)
        XCTAssertFalse(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPMCBC_removeLast1_remove0_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: false,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: false)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }
    func testCanEditPaymentMethods_TwoPMCBC_removeLast1_remove1_notCBCEligible() {
        let configuration = savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: true,
                                                      allowsRemovalOfPaymentMethods: true)
        let controller = savedPaymentOptionsController(configuration,
                                                       savedPaymentMethods: [STPPaymentMethod._testCard(), STPPaymentMethod._testCardCoBranded()],
                                                       cbcEligible: false)
        XCTAssertTrue(controller.canEditPaymentMethods)
    }

    // MARK: Helpers
    func savedPaymentOptionsConfig(allowsRemovalOfLastSavedPaymentMethod: Bool, allowsRemovalOfPaymentMethods: Bool) -> SavedPaymentOptionsViewController.Configuration {
        return SavedPaymentOptionsViewController.Configuration(customerID: "cus_123",
                                                               showApplePay: true,
                                                               showLink: true,
                                                               removeSavedPaymentMethodMessage: nil,
                                                               merchantDisplayName: "abc",
                                                               isCVCRecollectionEnabled: true,
                                                               isTestMode: true,
                                                               allowsRemovalOfLastSavedPaymentMethod: allowsRemovalOfLastSavedPaymentMethod,
                                                               allowsRemovalOfPaymentMethods: allowsRemovalOfPaymentMethods)
    }

    func savedPaymentOptionsController(_ configuration: SavedPaymentOptionsViewController.Configuration,
                                       savedPaymentMethods: [STPPaymentMethod],
                                       cbcEligible: Bool) -> SavedPaymentOptionsViewController {
        return SavedPaymentOptionsViewController(savedPaymentMethods: savedPaymentMethods,
                                                 configuration: configuration,
                                                 paymentSheetConfiguration: paymentSheetConfiguration,
                                                 intent: Intent._testValue(),
                                                 appearance: .default,
                                                 cbcEligible: cbcEligible,
                                                 delegate: nil)
    }
}
