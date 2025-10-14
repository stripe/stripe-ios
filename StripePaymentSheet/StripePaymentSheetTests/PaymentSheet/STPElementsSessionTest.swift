//
//  STPElementsSessionTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 2/16/23.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP)@_spi(ExperimentalAllowsRemovalOfLastSavedPaymentMethodAPI) import StripePaymentSheet
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
        XCTAssertFalse(elementsSession.paymentMethodSetAsDefaultForPaymentSheet)
        XCTAssertEqual(elementsSession.allResponseFields as NSDictionary, elementsSessionJson as NSDictionary)
    }

    func testDecodedObjectFromAPIResponseMapping_passiveCaptcha() {
        var elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")!
        elementsSessionJson["flags"] = ["elements_enable_passive_captcha": true]
        elementsSessionJson["passive_captcha"] = ["site_key": "20000000-ffff-ffff-ffff-000000000002", "rqdata": nil]

        var elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        XCTAssertNotNil(elementsSession.passiveCaptchaData)

        elementsSessionJson["passive_captcha"] = ["site_key": "20000000-ffff-ffff-ffff-000000000002"]
        elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        XCTAssertNotNil(elementsSession.passiveCaptchaData)

        elementsSessionJson["passive_captcha"] = ["rqdata": "data"]
        elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        XCTAssertNil(elementsSession.passiveCaptchaData)

        elementsSessionJson["flags"] = ["elements_enable_passive_captcha": false]
        elementsSessionJson["passive_captcha"] = ["site_key": "20000000-ffff-ffff-ffff-000000000002", "rqdata": nil]
        elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        XCTAssertNil(elementsSession.passiveCaptchaData)
    }

    func testDecodedObjectFromAPIResponseMapping_applePayPreferenceDisabled() {
        var elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")!
        elementsSessionJson["apple_pay_preference"] = "disabled"
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!

        XCTAssertFalse(elementsSession.isApplePayEnabled)
    }

    func testDecodedObjectFromAPIResponseMapping_merchantLogoUrl() {
        // nil merchant_logo_url
        var elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")!
        elementsSessionJson["merchant_logo_url"] = nil
        var elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        XCTAssertNil(elementsSession.merchantLogoUrl)

        // invalid URL string
        elementsSessionJson["merchant_logo_url"] = "invalid url"
        elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        XCTAssertNil(elementsSession.merchantLogoUrl)

        // valid URL string
        elementsSessionJson["merchant_logo_url"] = "https://example.com/valid-logo.png"
        elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        XCTAssertNotNil(elementsSession.merchantLogoUrl)
        XCTAssertEqual(elementsSession.merchantLogoUrl?.absoluteString, "https://example.com/valid-logo.png")
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

    func testFailedCPMParsing() {
        // If STPElementsSession decodes a dict...
        var elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")!
        // ...that contains unparseable custom_payment_method_data
        elementsSessionJson["custom_payment_method_data"] = [
            "this dict doesn't match the expected shape": "and will fail to parse",
        ]
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        // ...it should successfully decode...
        XCTAssertNotNil(elementsSession)
        // ...with an empty `customPaymentMethods` property
        XCTAssertTrue(elementsSession.customPaymentMethods.isEmpty)
        // ...and send a failure analytic
        let analyticEvents = STPAnalyticsClient.sharedClient._testLogHistory
        XCTAssertTrue(analyticEvents.contains(where: { dict in
            (dict["event"] as? String) == STPAnalyticEvent.paymentSheetElementsSessionCPMLoadFailed.rawValue
        }))
    }

    func testSuccessCPMParsing() {
        // If STPElementsSession decodes a dict...
        var elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")!

        let customPaymentMethodsArray: [[String: Any]] = [
            [
                "logo_url": "https://stripe.com",
                "display_name": "BufoPay (test)",
                "type": "cpmt_123",
                "error": NSNull(),
                "is_preset": false,
            ],
            [
                "logo_url": NSNull(),
                "display_name": NSNull(),
                "type": "cpmt_invalid",
                "error": "not_found",
                "is_preset": NSNull(),
            ],
        ]

        // ...that contains parseable custom_payment_method_data
        elementsSessionJson["custom_payment_method_data"] = customPaymentMethodsArray
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        // ...it should successfully decode...
        XCTAssertNotNil(elementsSession)
        // ...with a populated `customPaymentMethods` property
        XCTAssertEqual(2, elementsSession.customPaymentMethods.count)

        // ...validate first CPM
        let firstCPM = elementsSession.customPaymentMethods[0]
        XCTAssertEqual(firstCPM.displayName, "BufoPay (test)")
        XCTAssertEqual(firstCPM.type, "cpmt_123")
        XCTAssertEqual(firstCPM.logoUrl?.absoluteString, "https://stripe.com")
        XCTAssertFalse(firstCPM.isPreset ?? true)
        XCTAssertNil(firstCPM.error)

        // ...validate second CPM (error case)
        let errorCPM = elementsSession.customPaymentMethods[1]
        XCTAssertNil(errorCPM.displayName)
        XCTAssertEqual(errorCPM.type, "cpmt_invalid")
        XCTAssertNil(errorCPM.logoUrl)
        XCTAssertEqual(errorCPM.error, "not_found")
        XCTAssertNil(errorCPM.isPreset)

        // ...and not send a failure analytic
        let analyticEvents = STPAnalyticsClient.sharedClient._testLogHistory
        XCTAssertFalse(analyticEvents.contains(where: { dict in
            (dict["event"] as? String) == STPAnalyticEvent.paymentSheetElementsSessionCPMLoadFailed.rawValue
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
        XCTAssertTrue(elementsSession.customer!.customerSession.mobilePaymentElementComponent.features!.paymentMethodRemoveLast)
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
        XCTAssertFalse(elementsSession.paymentMethodRemoveIsPartialForPaymentSheet())
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

    func testSPMConsentAndRemoval_pmsE_pmrPartial() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "partial",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])

        let savePaymentMethodConsentBehavior = elementsSession.savePaymentMethodConsentBehavior
        let allowsRemoval = elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()

        XCTAssertTrue(allowsRemoval)
        XCTAssertTrue(elementsSession.paymentMethodRemoveIsPartialForPaymentSheet())
        XCTAssertEqual(.paymentSheetWithCustomerSessionPaymentMethodSaveEnabled, savePaymentMethodConsentBehavior)
    }

    func testSPMConsentAndRemoval_pmsD_pmrPartial() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "disabled",
                                                                                 "payment_method_remove": "partial",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])

        let savePaymentMethodConsentBehavior = elementsSession.savePaymentMethodConsentBehavior
        let allowsRemoval = elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()

        XCTAssertTrue(allowsRemoval)
        XCTAssertTrue(elementsSession.paymentMethodRemoveIsPartialForPaymentSheet())
        XCTAssertEqual(.paymentSheetWithCustomerSessionPaymentMethodSaveDisabled, savePaymentMethodConsentBehavior)
    }
    func testPaymentMethodRemoveLast_enabled() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                 "payment_method_remove_last": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])

        let allowsRemoval = elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()

        XCTAssertTrue(allowsRemoval)
        XCTAssertFalse(elementsSession.paymentMethodRemoveIsPartialForPaymentSheet())
        XCTAssertTrue(elementsSession.customer!.customerSession.mobilePaymentElementComponent.features!.paymentMethodRemoveLast)

        // Test that local config can override behavior
        var configuration1 = PaymentSheet.Configuration()
        configuration1.allowsRemovalOfLastSavedPaymentMethod = false
        XCTAssertFalse(elementsSession.paymentMethodRemoveLast(configuration: configuration1))

        // Test that local config works in w/ customerSession
        var configuration2 = PaymentSheet.Configuration()
        configuration2.allowsRemovalOfLastSavedPaymentMethod = true
        XCTAssertTrue(elementsSession.paymentMethodRemoveLast(configuration: configuration2))
    }
    func testPaymentMethodRemoveLast_disabled() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                 "payment_method_remove_last": "disabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])

        let allowsRemoval = elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()

        XCTAssertTrue(allowsRemoval)
        XCTAssertFalse(elementsSession.paymentMethodRemoveIsPartialForPaymentSheet())
        XCTAssertFalse(elementsSession.customer!.customerSession.mobilePaymentElementComponent.features!.paymentMethodRemoveLast)

        // Test that local config can override behavior
        var configuration1 = PaymentSheet.Configuration()
        configuration1.allowsRemovalOfLastSavedPaymentMethod = false
        XCTAssertFalse(elementsSession.paymentMethodRemoveLast(configuration: configuration1))

        // Test that local config works in w/ customerSession
        var configuration2 = PaymentSheet.Configuration()
        configuration2.allowsRemovalOfLastSavedPaymentMethod = true
        XCTAssertFalse(elementsSession.paymentMethodRemoveLast(configuration: configuration2))
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

    func testSetAsDefault_enabled() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                 "payment_method_set_as_default": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false,
                                                                ],
                                                            ])

        let allowsSetAsDefault = elementsSession.paymentMethodSetAsDefaultForPaymentSheet
        XCTAssertTrue(allowsSetAsDefault)
    }

    func testSetAsDefault_disabled() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                 "payment_method_set_as_default": "disabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false,
                                                                ],
                                                            ])

        let allowsSetAsDefault = elementsSession.paymentMethodSetAsDefaultForPaymentSheet
        XCTAssertFalse(allowsSetAsDefault)
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
        XCTAssertFalse(elementsSession.paymentMethodRemoveIsPartialForCustomerSheet())
        XCTAssertTrue(elementsSession.paymentMethodRemoveLastForCustomerSheet)
    }

    func testAllowsRemovalOfPaymentMethodsForCustomerSheet_partial() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": false
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_remove": "partial",
                                                                                ],
                                                                ],
                                                              ])

        let allowsRemoval = elementsSession.allowsRemovalOfPaymentMethodsForCustomerSheet()

        XCTAssertTrue(allowsRemoval)
        XCTAssertTrue(elementsSession.paymentMethodRemoveIsPartialForCustomerSheet())
        XCTAssertTrue(elementsSession.paymentMethodRemoveLastForCustomerSheet)
    }
    func testAllowsRemovalOfPaymentMethodsForCustomerSheet_removeLast_enabled() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": false
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_remove": "enabled",
                                                                                 "payment_method_remove_last": "enabled",
                                                                                ],
                                                                ],
                                                            ])

        let allowsRemoval = elementsSession.allowsRemovalOfPaymentMethodsForCustomerSheet()
        XCTAssertTrue(allowsRemoval)
        XCTAssertFalse(elementsSession.paymentMethodRemoveIsPartialForCustomerSheet())
        XCTAssertTrue(elementsSession.paymentMethodRemoveLastForCustomerSheet)
    }
    func testAllowsRemovalOfPaymentMethodsForCustomerSheet_removeLast_disabled() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": false
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_remove": "enabled",
                                                                                 "payment_method_remove_last": "disabled",
                                                                                ],
                                                                ],
                                                              ])

        let allowsRemoval = elementsSession.allowsRemovalOfPaymentMethodsForCustomerSheet()
        XCTAssertTrue(allowsRemoval)
        XCTAssertFalse(elementsSession.paymentMethodRemoveIsPartialForCustomerSheet())
        XCTAssertFalse(elementsSession.paymentMethodRemoveLastForCustomerSheet)
    }
    func testSetAsDefaultForCustomerSheet_enabled() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": false
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_remove": "enabled",
                                                                        "payment_method_sync_default": "enabled",
                                                                                ],
                                                                ],
                                                            ])

        let allowsSetAsDefault = elementsSession.paymentMethodSyncDefaultForCustomerSheet
        XCTAssertTrue(allowsSetAsDefault)
        XCTAssertFalse(elementsSession.paymentMethodRemoveIsPartialForCustomerSheet())
    }
    func testSetAsDefaultForCustomerSheet_disabled() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": false
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_sync_default": "disabled"],
                                                                ],
                                                            ])

        let allowsSetAsDefault = elementsSession.paymentMethodSyncDefaultForCustomerSheet
        XCTAssertFalse(allowsSetAsDefault)
        XCTAssertFalse(elementsSession.paymentMethodRemoveIsPartialForCustomerSheet())
    }
    func testCanDeserializeMPEWithoutCS() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "mobile_payment_element": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                 "payment_method_set_as_default": "enabled",
                                                                                ],
                                                                ],
                                                            ])

        let allowsSetAsDefault = elementsSession.paymentMethodSetAsDefaultForPaymentSheet
        XCTAssertTrue(allowsSetAsDefault)
    }
    func testCanDeserializeCSWithoutMPE() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "customer_sheet": [
                                                                    "enabled": true,
                                                                    "features": [
                                                                        "payment_method_remove": "enabled",
                                                                        "payment_method_sync_default": "enabled",
                                                                    ],
                                                                ],
                                                            ])

        XCTAssertTrue(elementsSession.paymentMethodSyncDefaultForCustomerSheet)
    }

    private let testCardJSON = [
        "id": "pm_123card",
        "type": "card",
        "card": [
            "last4": "4242",
            "brand": "visa",
            "fingerprint": "B8XXs2y2JsVBtB9f",
            "networks": ["available": ["visa"]],
            "exp_month": "01",
            "exp_year": "2040",
        ],
    ] as [AnyHashable: Any]
    private let testCardAmexJSON = [
        "id": "pm_123amexcard",
        "type": "card",
        "card": [
            "last4": "0005",
            "brand": "amex",
        ],
    ] as [AnyHashable: Any]
    func testElementsCustomerDefaultPaymentMethod() {
        let elementsSession = STPElementsSession._testDefaultCardValue(defaultPaymentMethod: "pm_123card", paymentMethods: [testCardAmexJSON, testCardJSON])
        let customer = elementsSession.customer
        XCTAssertNotNil(customer)
        let defaultPaymentMethodId = customer?.defaultPaymentMethod
        XCTAssertNotNil(defaultPaymentMethodId)
        let defaultPaymentMethod = customer?.getDefaultOrFirstPaymentMethod()
        XCTAssertNotNil(defaultPaymentMethod)
        XCTAssertEqual(defaultPaymentMethod?.stripeId, defaultPaymentMethodId)
        XCTAssertEqual(defaultPaymentMethod?.stripeId, "pm_123card")
    }
    func testElementsCustomerNoDefaultPaymentMethodHasSavedPaymentMethods() {
        let elementsSession = STPElementsSession._testDefaultCardValue(defaultPaymentMethod: nil, paymentMethods: [testCardAmexJSON, testCardJSON])
        let customer = elementsSession.customer
        XCTAssertNotNil(customer)
        let defaultPaymentMethodId = customer?.defaultPaymentMethod
        XCTAssertNil(defaultPaymentMethodId)
        let defaultPaymentMethod = customer?.getDefaultOrFirstPaymentMethod()
        XCTAssertNotNil(defaultPaymentMethod)
        XCTAssertEqual(defaultPaymentMethod?.stripeId, "pm_123amexcard")
    }
    func testElementsCustomerNoDefaultPaymentMethodNoSavedPaymentMethods() {
        let elementsSession = STPElementsSession._testDefaultCardValue(defaultPaymentMethod: nil, paymentMethods: [])
        let customer = elementsSession.customer
        XCTAssertNotNil(customer)
        let defaultPaymentMethodId = customer?.defaultPaymentMethod
        XCTAssertNil(defaultPaymentMethodId)
        let defaultPaymentMethod = customer?.getDefaultOrFirstPaymentMethod()
        XCTAssertNil(defaultPaymentMethod)
    }
}
