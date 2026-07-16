//
//  PaymentSheetVerticalViewControllerTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 6/4/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@_spi(STP) import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

@MainActor
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

    func testInitialScreen() throws {
        let analyticsClientV2 = MockAnalyticsClientV2()
        let arbId = "arb_pmm_123"
        let experimentsData = ExperimentsData(
            arbId: arbId,
            experimentAssignments: [
                PaymentMethodMessagingPromotionsExperiment.experimentName: .treatment,
            ],
            allResponseFields: [:]
        )
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: PaymentSheet.Configuration(),
            analyticsClient: STPTestingAnalyticsClient(),
            analyticsClientV2: analyticsClientV2
        )

        func makeViewController(loadResult: PaymentSheetLoader.LoadResult) -> PaymentSheetVerticalViewController {
            return PaymentSheetVerticalViewController(
                configuration: ._testValue_MostPermissive(),
                loadResult: loadResult,
                isFlowController: false,
                analyticsHelper: analyticsHelper,
                previousPaymentOption: nil
            )
        }
        // TODO: Test other things like `selectedPaymentOption`
        // If there are saved PMs, always show the list, even if there's only one other PM
        let elementsSession = STPElementsSession._testValue(experimentsData: experimentsData)
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let promotionsHelper = try XCTUnwrap(PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: PaymentSheet.Configuration(),
            paymentMethodTypes: [.stripe(.card)],
            analyticsHelper: analyticsHelper
        ))
        promotionsHelper.fetchData()
        let savedPMsLoadResult = PaymentSheetLoader.LoadResult(
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: promotionsHelper,
            paymentMethodOrientation: .vertical
        )
        XCTAssertTrue(makeViewController(loadResult: savedPMsLoadResult).children.first is VerticalPaymentMethodListViewController)

        // Verify PMM experiment exposure was logged exactly once with correct params
        let exposurePayloads = analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName)
        XCTAssertEqual(exposurePayloads.count, 1)
        if let payload = exposurePayloads.first {
            XCTAssertEqual(payload["arb_id"] as? String, arbId)
            XCTAssertEqual(payload["experiment_retrieved"] as? String, PaymentMethodMessagingPromotionsExperiment.experimentName)
            XCTAssertEqual(payload["assignment_group"] as? String, ExperimentGroup.treatment.rawValue)
        }

        // If there are no saved payment methods and we have only one payment method and it collects user input, display the form directly
        let formDirectlyResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
        XCTAssertTrue(makeViewController(loadResult: formDirectlyResult).children.first is PaymentMethodFormViewController)

        // If there are no saved payment methods and we have only one payment method and it doesn't collect user input, display the list
        let onlyOnePM = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
        XCTAssertTrue(makeViewController(loadResult: onlyOnePM).children.first is VerticalPaymentMethodListViewController)

        // If there are no saved payment methods and we have multiple PMs, display the list
        let multiplePMs = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
        XCTAssertTrue(makeViewController(loadResult: multiplePMs).children.first is VerticalPaymentMethodListViewController)

        // If there are no saved payment methods and we have one PM and Link, display the list
        let onePMAndLink = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
        XCTAssertTrue(makeViewController(loadResult: onePMAndLink).children.first is VerticalPaymentMethodListViewController)

        // If there are no saved payment methods and we have one PM and Apple Pay, display the list
        let onePMAndApplePay = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
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
                paymentMethodTypes: [.stripe(.card)],
                paymentMethodMessagingPromotionsHelper: ._testValue(),
                paymentMethodOrientation: .vertical
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
                paymentMethodTypes: [.stripe(.card)],
                paymentMethodMessagingPromotionsHelper: ._testValue(),
                paymentMethodOrientation: .vertical
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
}
