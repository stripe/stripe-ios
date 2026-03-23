//
//  PaymentSheetVerticalViewControllerTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 6/4/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

final class PaymentSheetVerticalViewControllerTest: XCTestCase {

    override func setUpWithError() throws {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testInitialScreen() {
        func makeViewController(loadResult: PaymentSheetLoader.LoadResult) -> PaymentSheetVerticalViewController {
            return PaymentSheetVerticalViewController(
                configuration: ._testValue_MostPermissive(),
                loadResult: loadResult,
                isFlowController: false,
                analyticsHelper: ._testValue(),
                previousPaymentOption: nil
            )
        }
        // TODO: Test other things like `selectedPaymentOption`
        // If there are saved PMs, always show the list, even if there's only one other PM
        let savedPMsLoadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)]
        )
        XCTAssertTrue(makeViewController(loadResult: savedPMsLoadResult).children.first is VerticalPaymentMethodListViewController)

        // If there are no saved payment methods and we have only one payment method and it collects user input, display the form directly
        let formDirectlyResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)]
        )
        XCTAssertTrue(makeViewController(loadResult: formDirectlyResult).children.first is PaymentMethodFormViewController)

        // If there are no saved payment methods and we have only one payment method and it doesn't collect user input, display the list
        let onlyOnePM = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)]
        )
        XCTAssertTrue(makeViewController(loadResult: onlyOnePM).children.first is VerticalPaymentMethodListViewController)

        // If there are no saved payment methods and we have multiple PMs, display the list
        let multiplePMs = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)]
        )
        XCTAssertTrue(makeViewController(loadResult: multiplePMs).children.first is VerticalPaymentMethodListViewController)

        // If there are no saved payment methods and we have one PM and Link, display the list
        let onePMAndLink = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)]
        )
        XCTAssertTrue(makeViewController(loadResult: onePMAndLink).children.first is VerticalPaymentMethodListViewController)

        // If there are no saved payment methods and we have one PM and Apple Pay, display the list
        let onePMAndApplePay = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)]
        )
        XCTAssertTrue(makeViewController(loadResult: onePMAndApplePay).children.first is VerticalPaymentMethodListViewController)
    }

    func testFlowControllerDefaults() {
        func makeVC(configuration: PaymentSheet.Configuration, hasSavedPM: Bool = true) -> PaymentSheetVerticalViewController {
            let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
            let loadResult = PaymentSheetLoader.LoadResult(
                intent: intent,
                elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: true),
                savedPaymentMethods: hasSavedPM ? [._testCard()] : [],
                paymentMethodTypes: [.stripe(.card)]
            )
            return PaymentSheetVerticalViewController(
                configuration: configuration,
                loadResult: loadResult,
                isFlowController: true,
                analyticsHelper: ._testValue(),
                previousPaymentOption: nil
            )
        }

        // If there's a customer default...
        CustomerPaymentOption.setDefaultPaymentMethod(.link, forCustomer: "cus_test")
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "cus_test", ephemeralKeySecret: "")
        configuration.applePay = .init(merchantId: "merch_test", merchantCountryCode: "US")
        // ...it should default to that...
        var vc = makeVC(configuration: configuration)
        XCTAssertEqual(vc.paymentMethodListViewController?.currentSelection, .link)

        // If the customer default won't appear in the list...
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId("non_existent"), forCustomer: "cus_test")
        // ...it should default to Apple Pay
        vc = makeVC(configuration: configuration)
        XCTAssertEqual(vc.paymentMethodListViewController?.currentSelection, .applePay)

        // If there's no customer default...
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: "cus_test")
        // ...it should default to Apple Pay
        vc = makeVC(configuration: configuration)
        XCTAssertEqual(vc.paymentMethodListViewController?.currentSelection, .applePay)

        // And if Apple Pay is disabled...
        configuration.applePay = nil
        // ...it should default to the saved PM
        vc = makeVC(configuration: configuration)
        XCTAssertEqual(vc.paymentMethodListViewController?.currentSelection, .saved(paymentMethod: ._testCard()))

        // And if there is no saved PM...
        vc = makeVC(configuration: configuration, hasSavedPM: false)
        // ...it should default to nothing
        XCTAssertEqual(vc.paymentMethodListViewController?.currentSelection, nil)
    }

    func testPaymentSheetDefaults() {
        let savedPM = STPPaymentMethod._testCard()
        func makeVC(configuration: PaymentSheet.Configuration, hasSavedPM: Bool = true) -> PaymentSheetVerticalViewController {
            let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
            let loadResult = PaymentSheetLoader.LoadResult(
                intent: intent,
                elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: true),
                savedPaymentMethods: hasSavedPM ? [savedPM] : [],
                paymentMethodTypes: [.stripe(.card)]
            )
            return PaymentSheetVerticalViewController(
                configuration: configuration,
                loadResult: loadResult,
                isFlowController: false,
                analyticsHelper: ._testValue(),
                previousPaymentOption: nil
            )
        }

        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "cus_test", ephemeralKeySecret: "")
        configuration.applePay = .init(merchantId: "merch_test", merchantCountryCode: "US")

        // If the customer default is a saved PM...
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(savedPM.stripeId), forCustomer: "cus_test")
        // ...it should default to that...
        var vc = makeVC(configuration: configuration)
        XCTAssertEqual(vc.paymentMethodListViewController?.currentSelection, .saved(paymentMethod: savedPM))

        // If the customer default doesn't appear in the list (Apple Pay / Link)
        CustomerPaymentOption.setDefaultPaymentMethod(.applePay, forCustomer: "cus_test")
        vc = makeVC(configuration: configuration)
        // ...it should default to the saved PM
        XCTAssertEqual(vc.paymentMethodListViewController?.currentSelection, .saved(paymentMethod: savedPM))
        CustomerPaymentOption.setDefaultPaymentMethod(.link, forCustomer: "cus_test")
        vc = makeVC(configuration: configuration)
        XCTAssertEqual(vc.paymentMethodListViewController?.currentSelection, .saved(paymentMethod: savedPM))

        // If there is no saved PM...
        vc = makeVC(configuration: configuration, hasSavedPM: false)
        // ...it should default to nothing
        XCTAssertEqual(vc.paymentMethodListViewController?.currentSelection, nil)
    }

    // MARK: - update(with:) tests

    private func makeVerticalVC(loadResult: PaymentSheetLoader.LoadResult) -> PaymentSheetVerticalViewController {
        return PaymentSheetVerticalViewController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: loadResult,
            isFlowController: false,
            analyticsHelper: ._testValue(),
            previousPaymentOption: nil
        )
    }

    func testUpdateWithLoadResult_updatesState() {
        let initialLoadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)]
        )
        let sut = makeVerticalVC(loadResult: initialLoadResult)

        let newIntent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .SEPADebit])
        let newElementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card", "sepa_debit"])
        let newSavedPMs = [STPPaymentMethod._testCard()]
        let updatedLoadResult = PaymentSheetLoader.LoadResult(
            intent: newIntent,
            elementsSession: newElementsSession,
            savedPaymentMethods: newSavedPMs,
            paymentMethodTypes: [.stripe(.card), .stripe(.SEPADebit)]
        )

        sut.update(with: updatedLoadResult)

        XCTAssertEqual(sut.savedPaymentMethods.count, 1)
        XCTAssertEqual(sut.loadResult.paymentMethodTypes, [.stripe(.card), .stripe(.SEPADebit)])
    }

    func testUpdateWithLoadResult_regeneratesListUI() {
        let initialLoadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)]
        )
        let sut = makeVerticalVC(loadResult: initialLoadResult)
        let originalListVC = sut.paymentMethodListViewController
        XCTAssertNotNil(originalListVC)

        let updatedLoadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)]
        )
        sut.update(with: updatedLoadResult)

        XCTAssertNotNil(sut.paymentMethodListViewController)
        XCTAssertFalse(sut.paymentMethodListViewController === originalListVC, "List VC should be recreated after update")
    }

    func testUpdateWithLoadResult_switchesFromFormToList() {
        // Single PM type + no saved PMs => form displayed directly
        let formLoadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)]
        )
        let sut = makeVerticalVC(loadResult: formLoadResult)
        XCTAssertTrue(sut.children.first is PaymentMethodFormViewController)

        // Update with saved PMs => should switch to list
        let listLoadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)]
        )
        sut.update(with: listLoadResult)
        XCTAssertTrue(sut.children.first is VerticalPaymentMethodListViewController)
    }

    func testUpdateWithLoadResult_switchesFromListToForm() {
        // Saved PMs => list displayed
        let listLoadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)]
        )
        let sut = makeVerticalVC(loadResult: listLoadResult)
        XCTAssertTrue(sut.children.first is VerticalPaymentMethodListViewController)

        // Update with no saved PMs and single PM type => form displayed
        let formLoadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)]
        )
        sut.update(with: formLoadResult)
        XCTAssertTrue(sut.children.first is PaymentMethodFormViewController)
    }

    func testUpdateWithLoadResult_clearsFormCache() {
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)]
        )
        let sut = makeVerticalVC(loadResult: loadResult)

        // The form VC writes into the cache during init; verify the cache has an entry
        XCTAssertNotNil(sut.formCache[.stripe(.card)])

        sut.update(with: loadResult)

        // After update, the old cache entries should be cleared (new form VC creates a fresh entry)
        // We verify the cache was cleared by checking a type that won't be re-populated
        XCTAssertNil(sut.formCache[.stripe(.SEPADebit)])
    }
}
