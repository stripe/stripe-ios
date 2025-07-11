//
//  STPPaymentIntentParamsTest.swift
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 7/5/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentIntentParamsTest: XCTestCase {
    func testInit() {
        for params in [
            STPPaymentIntentParams(clientSecret: "secret"),
            STPPaymentIntentParams(),
            STPPaymentIntentParams(),
        ] {
            XCTAssertNotNil(params)
            XCTAssertNotNil(params.clientSecret)
            XCTAssertNotNil(params.additionalAPIParameters)
            XCTAssertEqual(params.additionalAPIParameters.count, 0)

            XCTAssertNil(params.stripeId, "invalid secrets, no stripeId")
            XCTAssertNil(params.sourceParams)
            XCTAssertNil(params.sourceId)
            XCTAssertNil(params.receiptEmail)
            XCTAssertNil(params.perform(NSSelectorFromString("saveSourceToCustomer")))
            XCTAssertNil(params.savePaymentMethod)
            XCTAssertNil(params.returnURL)
            XCTAssertNil(params.setAsDefaultPM)
            XCTAssertNil(params.setupFutureUsage)
            XCTAssertNil(params.useStripeSDK)
            XCTAssertNil(params.mandateData)
            XCTAssertNil(params.paymentMethodOptions)
            XCTAssertNil(params.shipping)
        }
    }

    func testDescription() {
        let params = STPPaymentIntentParams()
        XCTAssertNotNil(params.description)
    }

    // MARK: Deprecated Property

    // #pragma clang diagnostic push
    // #pragma clang diagnostic ignored "-Wdeprecated"
    func testReturnURLRenaming() {
        let params = STPPaymentIntentParams()

        XCTAssertNil(params.returnURL)
        XCTAssertNil(params.perform(NSSelectorFromString("returnUrl")))

        params.returnURL = "set via new name"
        XCTAssertEqual(params.perform(NSSelectorFromString("returnUrl")).takeUnretainedValue() as? NSString, "set via new name")

        params.perform(NSSelectorFromString("setReturnUrl:"), with: "set via old name")
        XCTAssertEqual(params.returnURL, "set via old name")
    }

    func testSaveSourceToCustomerRenaming() {
        let params = STPPaymentIntentParams()

        XCTAssertNil(params.perform(NSSelectorFromString("saveSourceToCustomer")))
        XCTAssertNil(params.savePaymentMethod)

        params.savePaymentMethod = NSNumber(value: false)
        XCTAssertEqual(params.perform(NSSelectorFromString("saveSourceToCustomer")).takeUnretainedValue() as? NSNumber, NSNumber(value: false))

        params.perform(NSSelectorFromString("setSaveSourceToCustomer:"), with: NSNumber(value: true))
        XCTAssertEqual(params.savePaymentMethod, NSNumber(value: true))
    }

    func testDefaultMandateData() {
        let params = STPPaymentIntentParams()

        // no configuration should have no mandateData
        XCTAssertNil(params.mandateData)

        params.paymentMethodParams = STPPaymentMethodParams()

        params.paymentMethodParams!.rawTypeString = "card"
        // card type should have no default mandateData
        XCTAssertNil(params.mandateData)

        for type in ["sepa_debit", "au_becs_debit", "bacs_debit"] {
            params.mandateData = nil
            params.paymentMethodParams!.rawTypeString = type
            // Mandate-required type should have mandateData
            XCTAssertNotNil(params.mandateData)
            XCTAssertEqual(
                params.mandateData!.customerAcceptance.onlineParams!.inferFromClient,
                NSNumber(value: true)
            )

            params.mandateData = STPMandateDataParams(
                customerAcceptance: STPMandateCustomerAcceptanceParams(
                    type: .offline,
                    onlineParams: nil
                )!
            )
            // Default behavior should not override custom setting
            XCTAssertNotNil(params.mandateData)
            XCTAssertNil(params.mandateData!.customerAcceptance.onlineParams)
        }
    }

    // #pragma clang diagnostic pop

    // MARK: STPFormEncodable Tests
    func testRootObjectName() {
        XCTAssertNil(STPPaymentIntentParams.rootObjectName())
    }

    func testPropertyNamesToFormFieldNamesMapping() {
        let params = STPPaymentIntentParams()

        let mapping = STPPaymentIntentParams.propertyNamesToFormFieldNamesMapping()

        for propertyName in mapping.keys {
            XCTAssertFalse(propertyName.contains(":"))
            XCTAssert(params.responds(to: NSSelectorFromString(propertyName)))
        }

        for formFieldName in mapping.values {
            XCTAssert(formFieldName.count > 0)
        }

        XCTAssertEqual(
            mapping.values.count,
            NSSet(array: (mapping as NSDictionary).allValues).count
        )
    }

    func testCopy() {
        let params = STPPaymentIntentParams(clientSecret: "test_client_secret")
        params.paymentMethodParams = STPPaymentMethodParams()
        params.paymentMethodId = "test_payment_method_id"
        params.savePaymentMethod = NSNumber(value: true)
        params.returnURL = "fake://testing_only"
        params.setAsDefaultPM = NSNumber(value: true)
        params.setupFutureUsage = STPPaymentIntentSetupFutureUsage(
            rawValue: Int(truncating: NSNumber(value: 1))
        )
        params.useStripeSDK = NSNumber(value: true)
        params.mandateData = STPMandateDataParams(
            customerAcceptance: STPMandateCustomerAcceptanceParams(
                type: .offline,
                onlineParams: nil
            )!
        )
        params.paymentMethodOptions = STPConfirmPaymentMethodOptions()
        params.additionalAPIParameters = [
            "other_param": "other_value"
        ]
        params.shipping = STPPaymentIntentShippingDetailsParams(
            address: STPPaymentIntentShippingDetailsAddressParams(line1: ""),
            name: ""
        )

        let paramsCopy = params.copy() as! STPPaymentIntentParams
        XCTAssertEqual(params.clientSecret, paramsCopy.clientSecret)
        XCTAssertEqual(params.paymentMethodId, paramsCopy.paymentMethodId)

        // assert equal, not equal objects, because this is a shallow copy
        XCTAssertEqual(params.paymentMethodParams, paramsCopy.paymentMethodParams)
        XCTAssertEqual(params.mandateData, paramsCopy.mandateData)
        XCTAssertEqual(params.shipping, paramsCopy.shipping)

        XCTAssertEqual(params.setupFutureUsage, STPPaymentIntentSetupFutureUsage.none)
        XCTAssertEqual(params.savePaymentMethod, paramsCopy.savePaymentMethod)
        XCTAssertEqual(params.returnURL, paramsCopy.returnURL)
        XCTAssertEqual(params.setAsDefaultPM, paramsCopy.setAsDefaultPM)
        XCTAssertEqual(params.useStripeSDK, paramsCopy.useStripeSDK)
        XCTAssertEqual(params.paymentMethodOptions, paramsCopy.paymentMethodOptions)
        XCTAssertEqual(
            params.additionalAPIParameters as NSDictionary,
            paramsCopy.additionalAPIParameters as NSDictionary
        )

    }

    func testClientSecretValidation() {
        XCTAssertFalse(
            STPPaymentIntentParams.isClientSecretValid("pi_12345"),
            "'pi_12345' is not a valid client secret."
        )
        XCTAssertFalse(
            STPPaymentIntentParams.isClientSecretValid("pi_12345_secret_"),
            "'pi_12345_secret_' is not a valid client secret."
        )
        XCTAssertFalse(
            STPPaymentIntentParams.isClientSecretValid(
                "pi_a1b2c3_secret_x7y8z9pi_a1b2c3_secret_x7y8z9"
            ),
            "'pi_a1b2c3_secret_x7y8z9pi_a1b2c3_secret_x7y8z9' is not a valid client secret."
        )
        XCTAssertFalse(
            STPPaymentIntentParams.isClientSecretValid("seti_a1b2c3_secret_x7y8z9"),
            "'seti_a1b2c3_secret_x7y8z9' is not a valid client secret."
        )

        XCTAssertTrue(
            STPPaymentIntentParams.isClientSecretValid("pi_a1b2c3_secret_x7y8z9"),
            "'pi_a1b2c3_secret_x7y8z9' is a valid client secret."
        )
        XCTAssertTrue(
            STPPaymentIntentParams.isClientSecretValid(
                "pi_1CkiBMLENEVhOs7YMtUehLau_secret_s4O8SDh7s6spSmHDw1VaYPGZA"
            ),
            "'pi_1CkiBMLENEVhOs7YMtUehLau_secret_s4O8SDh7s6spSmHDw1VaYPGZA' is a valid client secret."
        )

        // Test valid scoped client secrets
        XCTAssertTrue(
            STPPaymentIntentParams.isClientSecretValid("pi_3RddVUHh8VvNDQ8j1CFgLC0y_scoped_secret_JouqJt9ahCKgh6B9r6"),
            "'pi_3RddVUHh8VvNDQ8j1CFgLC0y_scoped_secret_JouqJt9ahCKgh6B9r6' is a valid scoped client secret."
        )
        XCTAssertTrue(
            STPPaymentIntentParams.isClientSecretValid("pi_1CkiBMLENEVhOs7YMtUehLau_scoped_secret_s4O8SDh7s6spSmHDw1VaYPGZA"),
            "'pi_1CkiBMLENEVhOs7YMtUehLau_scoped_secret_s4O8SDh7s6spSmHDw1VaYPGZA' is a valid scoped client secret."
        )

        // Test invalid scoped client secrets
        XCTAssertFalse(
            STPPaymentIntentParams.isClientSecretValid("pi_12345_scoped_secret_"),
            "'pi_12345_scoped_secret_' is not a valid client secret."
        )
    }
}
