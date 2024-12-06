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
        XCTAssertTrue(viewController.canRemoveOrEdit)
    }

    func testCanEdit_singlePaymentMethod_returnsFalse() {
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        var noRemovalConfiguration = PaymentSheet.Configuration()
        noRemovalConfiguration.allowsRemovalOfLastSavedPaymentMethod = false
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: noRemovalConfiguration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue())
        XCTAssertFalse(viewController.canRemoveOrEdit)
    }

    func testCanEdit_singleRemovableCoBrandedCard_returnsFalse() {
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue())
        XCTAssertFalse(viewController.canEditPaymentMethods) // Can't edit, merchant is not eligible for CBC
    }

    func testCanEdit_singlePaymentMethod_disallowsLastRemoval_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue())
        XCTAssertFalse(viewController.canRemoveOrEdit)
    }

    func testCanEdit_oneEditablePaymentMethod_disallowsLastRemoval_notCBCEligible_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue())
        XCTAssertFalse(viewController.canRemoveOrEdit)
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
        XCTAssertTrue(viewController.canRemoveOrEdit)
    }

}
