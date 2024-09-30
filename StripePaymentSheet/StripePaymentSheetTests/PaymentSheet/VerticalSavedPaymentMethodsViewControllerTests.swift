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
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: paymentMethods.first,
            paymentMethods: paymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue()
        )
        XCTAssertTrue(viewController.canRemovePaymentMethods)
    }

    func testCanRemovePaymentMethods_multiplePaymentMethods_disallowsRemoval_returnsTrue() {
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: paymentMethods.first,
            paymentMethods: paymentMethods,
            elementsSession: ._testValue(
                paymentMethodTypes: ["card"],
                customerSessionData: [
                    "mobile_payment_element": [
                        "enabled": true,
                        "features": ["payment_method_save": "enabled",
                                     "payment_method_remove": "disabled",
                                    ],
                    ],
                    "customer_sheet": [
                        "enabled": false
                    ],
                ]),
            analyticsHelper: ._testValue()
        )
        XCTAssertFalse(viewController.canRemovePaymentMethods)
    }

    func testCanRemovePaymentMethods_multiplePaymentMethods_disallowsLastRemoval_returnsTrue() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: paymentMethods.first,
            paymentMethods: paymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue()
        )
        XCTAssertTrue(viewController.canRemovePaymentMethods)
    }

    func testCanRemovePaymentMethods_singlePaymentMethod_returnsTrue() {
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: singlePaymentMethods.first,
            paymentMethods: singlePaymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue()
        )
        XCTAssertTrue(viewController.canRemovePaymentMethods)
    }

    func testCanRemovePaymentMethods_singlePaymentMethod_disallowsLastRemoval_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: singlePaymentMethods.first,
            paymentMethods: singlePaymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue()
        )
        XCTAssertFalse(viewController.canRemovePaymentMethods)
    }

    // MARK: canEdit tests
    func testCanEdit_multiplePaymentMethods_returnsTrue() {
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: paymentMethods.first,
                                                                       paymentMethods: paymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue())
        XCTAssertTrue(viewController.canEdit)
    }

    func testCanEdit_singlePaymentMethod_returnsFalse() {
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue())
        XCTAssertFalse(viewController.canEdit)
        // Should be in remove only mode
        XCTAssertTrue(viewController.isRemoveOnlyMode)
    }

    func testCanEdit_singleRemovableCoBrandedCard_returnsFalse() {
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue())
        XCTAssertFalse(viewController.canEdit) // Can't edit, merchant is not eligible for CBC
        XCTAssertTrue(viewController.isRemoveOnlyMode) // Only operation we can make with a single payment method in this case is remove
    }

    func testCanEdit_singlePaymentMethod_disallowsLastRemoval_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue())
        XCTAssertFalse(viewController.canEdit)
    }

    func testCanEdit_oneEditablePaymentMethod_disallowsLastRemoval_notCBCEligible_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue())
        XCTAssertFalse(viewController.canEdit)
    }

    func testCanEdit_oneEditablePaymentMethod_disallowsLastRemoval_isCBCEligible_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: singlePaymentMethods.first,
            paymentMethods: singlePaymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"],
                                         cardBrandChoiceData: [
                                            "eligible": true]),
            analyticsHelper: ._testValue()
        )
        XCTAssertTrue(viewController.canEdit)
    }

    // MARK: Remove only mode

    func testIsRemoveOnlyMode_singlePaymentMethod_isNotCBCEligible_returnsTrue() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = true
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: singlePaymentMethods.first,
            paymentMethods: singlePaymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue()
        )
        // The card is NOT co-branded and, we can't edit, enter remove only mode
        XCTAssertTrue(viewController.isRemoveOnlyMode)
    }

    func testIsRemoveOnlyMode_singlePaymentMethod_isCBCEligible_returnsTrue() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = true
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: singlePaymentMethods.first,
            paymentMethods: singlePaymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"],
                                         cardBrandChoiceData: ["eligible": true]),
            analyticsHelper: ._testValue()
        )
        // The card is NOT co-branded and, we can't edit, enter remove only mode
        XCTAssertTrue(viewController.isRemoveOnlyMode)
    }

    func testIsRemoveOnlyMode_singleCobrandedPaymentMethod_isCBCEligible_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = true
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: singlePaymentMethods.first,
            paymentMethods: singlePaymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"],
                                         cardBrandChoiceData: ["eligible": true]),
            analyticsHelper: ._testValue()
        )

        // The card is co-branded and the merchant is CBC eligible, we can edit, don't enter remove only mode
        XCTAssertFalse(viewController.isRemoveOnlyMode)
    }

    func testIsRemoveOnlyMode_singleCobrandedPaymentMethod_isNotCBCEligible_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = true
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: singlePaymentMethods.first,
            paymentMethods: singlePaymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue()
        )

        // The card is co-branded but the merchant is NOT CBC eligible, we can't edit, enter remove only mode
        XCTAssertTrue(viewController.isRemoveOnlyMode)
    }

}
