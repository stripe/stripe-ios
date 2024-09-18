//
//  STPElementsSessionTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 2/16/23.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
import XCTest

class STPElementsSessionTest: XCTestCase {

    override func tearDown() {
        STPAnalyticsClient.sharedClient._testLogHistory = []
        super.tearDown()
    }

    // MARK: - STPAPIResponseDecodable Tests
    func testDecodedObjectFromAPIResponseMapping() {
        var elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")!
        elementsSessionJson["unactivated_payment_method_types"] = ["cashapp"]
        elementsSessionJson["card_brand_choice"] = ["eligible": true]
        elementsSessionJson["flags"] = ["cbc_in_link_popup": true, "disable_cbc_in_link_popup": false]
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!

        XCTAssertEqual(
            elementsSession.orderedPaymentMethodTypes,
            [
                STPPaymentMethodType.card,
                STPPaymentMethodType.link,
                STPPaymentMethodType.USBankAccount,
                STPPaymentMethodType.afterpayClearpay,
                STPPaymentMethodType.klarna,
                STPPaymentMethodType.cashApp,
                STPPaymentMethodType.alipay,
                STPPaymentMethodType.weChatPay,
            ]
        )

        XCTAssertEqual(
            elementsSession.unactivatedPaymentMethodTypes,
            [STPPaymentMethodType.cashApp]
        )

        XCTAssertNotNil(elementsSession.linkSettings)
        XCTAssertEqual(elementsSession.countryCode, "US")
        XCTAssertEqual(elementsSession.merchantCountryCode, "US")
        XCTAssertNotNil(elementsSession.paymentMethodSpecs)
        XCTAssertEqual(elementsSession.cardBrandChoice?.eligible, true)
        XCTAssertEqual(elementsSession.flags, ["cbc_in_link_popup": true, "disable_cbc_in_link_popup": false])
        XCTAssertTrue(elementsSession.isApplePayEnabled)
        XCTAssertEqual(elementsSession.allResponseFields as NSDictionary, elementsSessionJson as NSDictionary)
    }

    func testDecodedObjectFromAPIResponseMapping_applePayPreferenceDisabled() {
        var elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")!
        elementsSessionJson["apple_pay_preference"] = "disabled"
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!

        XCTAssertFalse(elementsSession.isApplePayEnabled)
    }

    func testMissingEPMResponseDoesntFireAnalytic() {
        // If STPElementsSession decodes a dict...
        var elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")!
        // ...that doesn't contain "external_payment_method_data"
        elementsSessionJson["external_payment_method_data"] = nil
        var elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        // ...it should successfully decode...
        XCTAssertNotNil(elementsSession)
        // ...with an empty `externalPaymentMethods` property
        XCTAssertTrue(elementsSession.externalPaymentMethods.isEmpty)
        // ...and not send a failure analytic
        let analyticEvents = STPAnalyticsClient.sharedClient._testLogHistory
        XCTAssertFalse(analyticEvents.contains(where: { dict in
            (dict["event"] as? String) == STPAnalyticEvent.paymentSheetElementsSessionEPMLoadFailed.rawValue
        }))

        // Same test as above, but when "external_payment_method_data" is NSNull...
        elementsSessionJson["external_payment_method_data"] = NSNull()
        elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        // ...it should successfully decode...
        XCTAssertNotNil(elementsSession)
        // ...with an empty `externalPaymentMethods` property
        XCTAssertTrue(elementsSession.externalPaymentMethods.isEmpty)
        // ...and not send a failure analytic
        XCTAssertFalse(STPAnalyticsClient.sharedClient._testLogHistory.contains(where: { dict in
            (dict["event"] as? String) == STPAnalyticEvent.paymentSheetElementsSessionEPMLoadFailed.rawValue
        }))
    }

    func testFailedEPMParsing() {
        // If STPElementsSession decodes a dict...
        var elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")!
        // ...that contains unparseable external_payment_method_data
        elementsSessionJson["external_payment_method_data"] = [
            "this dict doesn't match the expected shape": "and will fail to parse",
        ]
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        // ...it should successfully decode...
        XCTAssertNotNil(elementsSession)
        // ...with an empty `externalPaymentMethods` property
        XCTAssertTrue(elementsSession.externalPaymentMethods.isEmpty)
        // ...and send a failure analytic
        let analyticEvents = STPAnalyticsClient.sharedClient._testLogHistory
        XCTAssertTrue(analyticEvents.contains(where: { dict in
            (dict["event"] as? String) == STPAnalyticEvent.paymentSheetElementsSessionEPMLoadFailed.rawValue
        }))
    }

    func testSPMConsentAndRemoval_legacy() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: nil)

        let savePaymentMethodConsentBehavior = elementsSession.savePaymentMethodConsentBehavior
        let allowsRemovalPS = elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()

        XCTAssertTrue(allowsRemovalPS)
        XCTAssertEqual(.legacy, savePaymentMethodConsentBehavior)
    }

    func testSPMConsentAndRemoval_pmsE_pmrE() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])

        let savePaymentMethodConsentBehavior = elementsSession.savePaymentMethodConsentBehavior
        let allowsRemoval = elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()

        XCTAssertTrue(allowsRemoval)
        XCTAssertEqual(.paymentSheetWithCustomerSessionPaymentMethodSaveEnabled, savePaymentMethodConsentBehavior)
    }
    func testSPMConsentAndRemoval_pmsD_pmrE() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "disabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])

        let savePaymentMethodConsentBehavior = elementsSession.savePaymentMethodConsentBehavior
        let allowsRemoval = elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()

        XCTAssertTrue(allowsRemoval)
        XCTAssertEqual(.paymentSheetWithCustomerSessionPaymentMethodSaveDisabled, savePaymentMethodConsentBehavior)
    }
    func testSPMConsentAndRemoval_pmsE_pmrD() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
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
                                                            ])

        let savePaymentMethodConsentBehavior = elementsSession.savePaymentMethodConsentBehavior
        let allowsRemoval = elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()

        XCTAssertFalse(allowsRemoval)
        XCTAssertEqual(.paymentSheetWithCustomerSessionPaymentMethodSaveEnabled, savePaymentMethodConsentBehavior)
    }
    func testSPMConsentAndRemoval_pmsD_pmrD() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "disabled",
                                                                                 "payment_method_remove": "disabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])

        let savePaymentMethodConsentBehavior = elementsSession.savePaymentMethodConsentBehavior
        let allowsRemoval = elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()

        XCTAssertFalse(allowsRemoval)
        XCTAssertEqual(.paymentSheetWithCustomerSessionPaymentMethodSaveDisabled, savePaymentMethodConsentBehavior)
    }
    func testSPMConsentAndRemoval_invalidComponent() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "payment_element": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])

        let savePaymentMethodConsentBehavior = elementsSession.savePaymentMethodConsentBehavior

        XCTAssertEqual(.legacy, savePaymentMethodConsentBehavior)
    }

    func testAllowsRemovalOfPaymentMethodsForCustomerSheet_legacy() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: nil)

        let allowsRemovalCS = elementsSession.allowsRemovalOfPaymentMethodsForCustomerSheet()

        XCTAssertTrue(allowsRemovalCS)
    }
    func testAllowsRemovalOfPaymentMethodsForCustomerSheet_enabled() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": false
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                            ])

        let allowsRemoval = elementsSession.allowsRemovalOfPaymentMethodsForCustomerSheet()

        XCTAssertTrue(allowsRemoval)
    }
    func testAllowsRemovalOfPaymentMethodsForCustomerSheet_disabled() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": false
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_remove": "disabled",
                                                                                ],
                                                                ],
                                                              ])

        let allowsRemoval = elementsSession.allowsRemovalOfPaymentMethodsForCustomerSheet()

        XCTAssertFalse(allowsRemoval)
    }
}
