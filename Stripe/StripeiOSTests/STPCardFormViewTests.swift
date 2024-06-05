//
//  STPCardFormViewTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 1/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPCardFormViewTests: XCTestCase {

    func testMarkFormErrorsLogic() {
        let cardForm = STPCardFormView()

        let handledErrorsTypes = [
            "incorrect_number",
            "invalid_number",
            "invalid_expiry_month",
            "invalid_expiry_year",
            "expired_card",
            "invalid_cvc",
            "incorrect_cvc",
            "incorrect_zip",
        ]

        let unhandledErrorTypes = [
            "card_declined",
            "processing_error",
            "imaginary_error",
            "",
            nil,
        ]

        for shouldHandle in handledErrorsTypes {
            let error = NSError(
                domain: STPError.stripeDomain,
                code: STPErrorCode.apiError.rawValue,
                userInfo: [STPError.stripeErrorCodeKey: shouldHandle]
            )
            XCTAssertTrue(
                cardForm.markFormErrors(for: error),
                "Failed to handle error for \(shouldHandle)"
            )
        }

        for shouldNotHandle in unhandledErrorTypes {
            let error: NSError
            if let shouldNotHandle = shouldNotHandle {
                error = NSError(
                    domain: STPError.stripeDomain,
                    code: STPErrorCode.apiError.rawValue,
                    userInfo: [STPError.stripeErrorCodeKey: shouldNotHandle]
                )
            } else {
                error = NSError(
                    domain: STPError.stripeDomain,
                    code: STPErrorCode.apiError.rawValue,
                    userInfo: nil
                )
            }
            XCTAssertFalse(
                cardForm.markFormErrors(for: error),
                "Incorrectly handled \(shouldNotHandle ?? "nil")"
            )
        }
    }

    func testHidingPostalCodeOnInit() {
        NSLocale.stp_withLocale(as: NSLocale(localeIdentifier: "zh_Hans_HK")) {
            let cardForm = STPCardFormView()
            XCTAssertTrue(cardForm.postalCodeField.isHidden)
        }
    }

    func testHidingPostalUPECodeOnInit() {
        NSLocale.stp_withLocale(as: NSLocale(localeIdentifier: "zh_Hans_HK")) {
            let cardForm = STPCardFormView(
                billingAddressCollection: .automatic,
                style: .standard,
                postalCodeRequirement: .upe,
                prefillDetails: nil
            )
            XCTAssertTrue(cardForm.postalCodeField.isHidden)
        }
    }

    func testNotHidingPostalUPECodeOnInit() {
        NSLocale.stp_withLocale(as: NSLocale(localeIdentifier: "en_US")) {
            let cardForm = STPCardFormView(
                billingAddressCollection: .automatic,
                style: .standard,
                postalCodeRequirement: .upe,
                prefillDetails: nil
            )
            XCTAssertFalse(cardForm.postalCodeField.isHidden)
        }
    }

    func testPanLockedOnInit() {
        NSLocale.stp_withLocale(as: NSLocale(localeIdentifier: "en_US")) {
            let cardForm = STPCardFormView(
                billingAddressCollection: .automatic,
                style: .standard,
                postalCodeRequirement: .upe,
                prefillDetails: nil,
                inputMode: .panLocked
            )
            XCTAssertFalse(cardForm.numberField.isUserInteractionEnabled)
        }
    }

    func testPrefilledOnInit() {
        let prefillDeatils = STPCardFormView.PrefillDetails(
            last4: "4242",
            expiryMonth: 12,
            expiryYear: 25,
            cardBrand: .amex
        )
        NSLocale.stp_withLocale(as: NSLocale(localeIdentifier: "en_US")) {
            let cardForm = STPCardFormView(
                billingAddressCollection: .automatic,
                style: .standard,
                postalCodeRequirement: .upe,
                prefillDetails: prefillDeatils,
                inputMode: .panLocked
            )

            XCTAssertEqual(cardForm.numberField.text, prefillDeatils.formattedLast4)
            XCTAssertEqual(cardForm.numberField.cardBrandState.brand, prefillDeatils.cardBrand)
            XCTAssertEqual(cardForm.expiryField.text, prefillDeatils.formattedExpiry)
            XCTAssertEqual(cardForm.cvcField.cardBrand, prefillDeatils.cardBrand)
        }
    }

    func testCBCWithPreferredNetwork() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let cardFormView = STPCardFormView(billingAddressCollection: .automatic, cbcEnabledOverride: true)
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "5555552500001001"
        cardParams.expYear = 2050
        cardParams.expMonth = 12
        cardParams.cvc = "123"
        cardParams.networks = .init(preferred: "cartes_bancaires")
        let billingDetails = STPPaymentMethodBillingDetails(postalCode: "12345", countryCode: "US")
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)
        cardFormView.cardParams = paymentMethodParams
        XCTAssertEqual(cardFormView.cardParams?.card?.number, cardParams.number)
        let exp = expectation(description: "Wait for CBC load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertEqual(cardFormView.cardParams?.card?.networks?.preferred, "cartes_bancaires")
            XCTAssertEqual(cardFormView.numberField.cardBrandState.brand, .cartesBancaires)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3.0)
    }

    func testCBCOBO() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let cardFormView = STPCardFormView(billingAddressCollection: .automatic, cbcEnabledOverride: true)
        cardFormView.onBehalfOf = "acct_abc123"
        XCTAssertEqual((cardFormView.numberField.validator as! STPCardNumberInputTextFieldValidator).cbcController.onBehalfOf, "acct_abc123")
    }

    func testCBCFourDigitCVCIsInvalid() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let cardFormView = STPCardFormView(billingAddressCollection: .automatic, cbcEnabledOverride: true)
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "5555552500001001"
        cardParams.expYear = 2050
        cardParams.expMonth = 12
        cardParams.cvc = "1234"
        let billingDetails = STPPaymentMethodBillingDetails(postalCode: "12345", countryCode: "US")
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)
        cardFormView.cardParams = paymentMethodParams
        let exp = expectation(description: "Wait for validation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(cardFormView.cvcField.isValid)
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }

    // MARK: Functional Tests
    // If these fail it's _possibly_ because the returned error formats have changed

    func helperFunctionalTestNumber(_ cardNumber: String, shouldHandle: Bool) {
        let createPaymentIntentExpectation = self.expectation(
            description: "createPaymentIntentExpectation"
        )
        var retrievedClientSecret: String?
        STPTestingAPIClient.shared.createPaymentIntent(withParams: nil) {
            (createdPIClientSecret, _) in
            if let createdPIClientSecret = createdPIClientSecret {
                retrievedClientSecret = createdPIClientSecret
                createPaymentIntentExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        wait(for: [createPaymentIntentExpectation], timeout: 8)  // STPTestingNetworkRequestTimeout
        guard let clientSecret = retrievedClientSecret,
            let currentYear = Calendar.current.dateComponents([.year], from: Date()).year
        else {
            XCTFail()
            return
        }

        // STPTestingDefaultPublishableKey
        let client = STPAPIClient(publishableKey: "pk_test_ErsyMEOTudSjQR8hh0VrQr5X008sBXGOu6")

        let expiryYear = NSNumber(value: currentYear + 2)
        let expiryMonth = NSNumber(1)

        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = cardNumber
        cardParams.expYear = expiryYear
        cardParams.expMonth = expiryMonth
        cardParams.cvc = "123"

        let address = STPPaymentMethodAddress()
        address.postalCode = "12345"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = address

        let paymentMethodParams = STPPaymentMethodParams.paramsWith(
            card: cardParams,
            billingDetails: billingDetails,
            metadata: nil
        )

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams

        let confirmExpectation = expectation(description: "confirmExpectation")
        client.confirmPaymentIntent(with: paymentIntentParams) { (_, error) in
            if let error = error {
                let cardForm = STPCardFormView()
                if shouldHandle {
                    XCTAssertTrue(
                        cardForm.markFormErrors(for: error),
                        "Failed to handle \(error) for \(cardNumber)"
                    )
                } else {
                    XCTAssertFalse(
                        cardForm.markFormErrors(for: error),
                        "Incorrectly handled \(error) for \(cardNumber)"
                    )
                }
                confirmExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        wait(for: [confirmExpectation], timeout: 8)  // STPTestingNetworkRequestTimeout
    }

    func testExpiredCard() {
        helperFunctionalTestNumber("4000000000000069", shouldHandle: true)
    }

    func testIncorrectCVC() {
        helperFunctionalTestNumber("4000000000000127", shouldHandle: true)
    }

    func testIncorrectCardNumber() {
        helperFunctionalTestNumber("4242424242424241", shouldHandle: true)
    }

    func testCardDeclined() {
        helperFunctionalTestNumber("4000000000000002", shouldHandle: false)
    }

    func testProcessingError() {
        helperFunctionalTestNumber("4000000000000119", shouldHandle: false)
    }
}
