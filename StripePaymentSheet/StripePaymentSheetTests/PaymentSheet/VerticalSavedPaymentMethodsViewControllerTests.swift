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
            intent: ._testValue(),
            selectedPaymentMethod: paymentMethods.first,
            paymentMethods: paymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue(),
            defaultPaymentMethod: nil
        )
        XCTAssertTrue(viewController.canRemovePaymentMethods)
    }

    func testCanRemovePaymentMethods_multiplePaymentMethods_disallowsRemoval_returnsTrue() {
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            intent: ._testValue(),
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
            analyticsHelper: ._testValue(),
            defaultPaymentMethod: nil
        )
        XCTAssertFalse(viewController.canRemovePaymentMethods)
    }

    func testCanRemovePaymentMethods_multiplePaymentMethods_disallowsLastRemoval_returnsTrue() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            intent: ._testValue(),
            selectedPaymentMethod: paymentMethods.first,
            paymentMethods: paymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue(),
            defaultPaymentMethod: nil
        )
        XCTAssertTrue(viewController.canRemovePaymentMethods)
    }

    func testCanRemovePaymentMethods_singlePaymentMethod_returnsTrue() {
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            intent: ._testValue(),
            selectedPaymentMethod: singlePaymentMethods.first,
            paymentMethods: singlePaymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue(),
            defaultPaymentMethod: nil
        )
        XCTAssertTrue(viewController.canRemovePaymentMethods)
    }

    func testCanRemovePaymentMethods_singlePaymentMethod_disallowsLastRemoval_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            intent: ._testValue(),
            selectedPaymentMethod: singlePaymentMethods.first,
            paymentMethods: singlePaymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue(),
            defaultPaymentMethod: nil
        )
        XCTAssertFalse(viewController.canRemovePaymentMethods)
    }

    // MARK: canEdit tests
    func testCanEdit_multiplePaymentMethods_returnsTrue() {
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       intent: ._testValue(),
                                                                       selectedPaymentMethod: paymentMethods.first,
                                                                       paymentMethods: paymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue(),
                                                                       defaultPaymentMethod: nil)
        XCTAssertTrue(viewController.canRemoveOrEdit)
    }

    func testCanEdit_singlePaymentMethod_returnsFalse() {
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        var noRemovalConfiguration = PaymentSheet.Configuration()
        noRemovalConfiguration.allowsRemovalOfLastSavedPaymentMethod = false
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: noRemovalConfiguration,
                                                                       intent: ._testValue(),
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue(),
                                                                       defaultPaymentMethod: nil)
        XCTAssertFalse(viewController.canRemoveOrEdit)
    }

    func testCanEdit_singleRemovableCoBrandedCard_returnsFalse() {
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       intent: ._testValue(),
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue(),
                                                                       defaultPaymentMethod: nil)
        XCTAssertFalse(viewController.canEditPaymentMethods) // Can't edit, merchant is not eligible for CBC
    }

    func testCanEdit_singlePaymentMethod_disallowsLastRemoval_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCard()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       intent: ._testValue(),
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue(),
                                                                       defaultPaymentMethod: nil)
        XCTAssertFalse(viewController.canRemoveOrEdit)
    }

    func testCanEdit_oneEditablePaymentMethod_disallowsLastRemoval_notCBCEligible_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                                       intent: ._testValue(),
                                                                       selectedPaymentMethod: singlePaymentMethods.first,
                                                                       paymentMethods: singlePaymentMethods,
                                                                       elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                                                                       analyticsHelper: ._testValue(),
                                                                       defaultPaymentMethod: nil)
        XCTAssertFalse(viewController.canRemoveOrEdit)
    }

    func testCanEdit_oneEditablePaymentMethod_disallowsLastRemoval_isCBCEligible_returnsFalse() {
        configuration.allowsRemovalOfLastSavedPaymentMethod = false
        let singlePaymentMethods = [STPPaymentMethod._testCardCoBranded()]
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            intent: ._testValue(),
            selectedPaymentMethod: singlePaymentMethods.first,
            paymentMethods: singlePaymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"],
                                         cardBrandChoiceData: [
                                            "eligible": true]),
            analyticsHelper: ._testValue(),
            defaultPaymentMethod: nil
        )
        XCTAssertTrue(viewController.canRemoveOrEdit)
    }

    func testCanRemovePaymentMethods_checkoutSessionWithoutDetachPermission_returnsFalse() {
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            intent: makeCheckoutSessionIntent(canDetachPaymentMethod: false),
            selectedPaymentMethod: paymentMethods.first,
            paymentMethods: paymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue(),
            defaultPaymentMethod: nil
        )

        XCTAssertFalse(viewController.canRemovePaymentMethods)
    }

    func testCanRemovePaymentMethods_checkoutSessionWithDetachPermission_returnsTrue() {
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            intent: makeCheckoutSessionIntent(canDetachPaymentMethod: true),
            selectedPaymentMethod: paymentMethods.first,
            paymentMethods: paymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue(),
            defaultPaymentMethod: nil
        )

        XCTAssertTrue(viewController.canRemovePaymentMethods)
    }

    private func makeCheckoutSessionIntent(canDetachPaymentMethod: Bool) -> Intent {
        let json: [String: Any] = [
            "session_id": "cs_test_123",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "customer": [
                "id": "cus_test_123",
                "payment_methods": [],
                "can_detach_payment_method": canDetachPaymentMethod,
            ],
        ]

        guard let checkoutSession = STPCheckoutSession.decodedObject(fromAPIResponse: json) else {
            fatalError("Failed to create checkout session test fixture")
        }
        return .checkoutSession(checkoutSession)
    }

}
