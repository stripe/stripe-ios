//
//  VerticalSavedPaymentMethodsViewControllerTests.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/15/24.
//

import Foundation
import StripeCoreTestUtils
@testable @_spi(STP) @_spi(ExperimentalAllowsRemovalOfLastSavedPaymentMethodAPI) import StripePaymentSheet
import XCTest

class VerticalSavedPaymentMethodsViewControllerTests: XCTestCase {

    var paymentMethods: [STPPaymentMethod]!
    var configuration: PaymentSheet.Configuration!

    override func setUp() {
        super.setUp()

        paymentMethods = [STPPaymentMethod._testCard(),
                          STPPaymentMethod._testCard(),
                          STPPaymentMethod._testCard(), ]
        configuration = PaymentSheet.Configuration()
    }

    // MARK: canRemovePaymentMethods tests
    func testCanRemovePaymentMethods_multiplePaymentMethods_returnsTrue() {
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: paymentMethods.first,
                                                                       paymentMethods: paymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: false)
        XCTAssertTrue(viewController.canRemovePaymentMethods)
    }

    func testCanRemovePaymentMethods_multiplePaymentMethods_disallowsLastRemoval_returnsTrue() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: paymentMethods.first,
                                                                       paymentMethods: paymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: false)
        XCTAssertTrue(viewController.canRemovePaymentMethods)
    }

    func testCanRemovePaymentMethods_singlePaymentMethod_returnsTrue() {
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: false)
        XCTAssertTrue(viewController.canRemovePaymentMethods)
    }

    func testCanRemovePaymentMethods_singlePaymentMethod_disallowsLastRemoval_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: false)
        XCTAssertFalse(viewController.canRemovePaymentMethods)
    }

    // MARK: canEdit tests
    func testCanEdit_multiplePaymentMethods_returnsTrue() {
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: paymentMethods.first,
                                                                       paymentMethods: paymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: false)
        XCTAssertTrue(viewController.canEdit)
    }

    func testCanEdit_singlePaymentMethod_returnsFalse() {
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: false)
        XCTAssertFalse(viewController.canEdit)
        // Should be in remove only mode
        XCTAssertTrue(viewController.isRemoveOnlyMode)
    }

    func testCanEdit_singleRemovableAndEditablePaymentMethod_returnsTrue() {
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: false)
        XCTAssertTrue(viewController.canEdit)
    }

    func testCanEdit_singlePaymentMethod_disallowsLastRemoval_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: false)
        XCTAssertFalse(viewController.canEdit)
    }

    func testCanEdit_oneEditablePaymentMethod_disallowsLastRemoval_notCBCEligible_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: false)
        XCTAssertFalse(viewController.canEdit)
    }

    func testCanEdit_oneEditablePaymentMethod_disallowsLastRemoval_isCBCEligible_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: true)
        XCTAssertTrue(viewController.canEdit)
    }

    // MARK: Remove only mode

    func testIsRemoveOnlyMode_singlePaymentMethod_isNotCBCEligible_returnsTrue() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = true
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: false)

        // The card is NOT co-branded and, we can't edit, enter remove only mode
        XCTAssertTrue(viewController.isRemoveOnlyMode)
    }

    func testIsRemoveOnlyMode_singlePaymentMethod_isCBCEligible_returnsTrue() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = true
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: true)

        // The card is NOT co-branded and, we can't edit, enter remove only mode
        XCTAssertTrue(viewController.isRemoveOnlyMode)
    }

    func testIsRemoveOnlyMode_singleCobrandedPaymentMethod_isCBCEligible_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = true
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: true)

        // The card is co-branded and the merchant is CBC eligible, we can edit, don't enter remove only mode
        XCTAssertFalse(viewController.isRemoveOnlyMode)
    }

    func testIsRemoveOnlyMode_singleCobrandedPaymentMethod_isNotCBCEligible_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = true
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       paymentMethodRemove: true,
                                                                       isCBCEligible: false)

        // The card is co-branded but the merchant is NOT CBC eligible, we can't edit, enter remove only mode
        XCTAssertTrue(viewController.isRemoveOnlyMode)
    }

}
