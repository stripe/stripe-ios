//
//  PaymentSheetLPMSnapshotTests.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/2/25.
//

import UIKit
import XCTest

@_spi(STP)@testable import StripeCore
@_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
@_spi(STP)@testable import StripeUICore

// 🙅‍♂️ ☠️ These tests are an anti-pattern, don't add to these tests unless you have a good reason!
extension PaymentSheetSnapshotTests {
    func testPaymentSheet_LPM_Affirm_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"affirm\"",
                        "<currency>": "\"usd\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            override_payment_methods_types: ["affirm"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_AfterpayClearpay_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_GB_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"afterpay_clearpay\"",
                        "<currency>": "\"gbp\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            override_payment_methods_types: ["afterpay_clearpay"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_CashAppAfterpay_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"afterpay_clearpay\"",
                        "<currency>": "\"usd\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            override_payment_methods_types: ["afterpay_clearpay"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_Afterpay_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_IT_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"afterpay_clearpay\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            override_payment_methods_types: ["afterpay_clearpay"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_klarna_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"klarna\"",
                        "<currency>": "\"usd\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            override_payment_methods_types: ["klarna"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_cashapp_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"cashapp\"",
                        "<currency>": "\"usd\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            override_payment_methods_types: ["cashapp"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_cashapp_only_applePayDisabled() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"cashapp\"",
                        "<currency>": "\"usd\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            override_payment_methods_types: ["cashapp"],
            automaticPaymentMethods: false,
            useLink: false,
            applePayEnabled: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_iDeal_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"ideal\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["ideal"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    func testPaymentSheet_LPM_iDeal_setupIntent_customerSession() {
        stubSessions(
            fileMock: .elementsSessions_customerSessionsMobilePaymentElement_setupIntent_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"ideal\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubCustomers()
        stubConsumerSession()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .setup(currency: "eur", setupFutureUsage: .offSession),
                                                            paymentMethodTypes: ["ideal"],
                                                            confirmHandler: confirmHandler(_:_:_:),
                                                            requireCVCRecollection: false)
        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["ideal"],
            automaticPaymentMethods: false,
            useLink: false,
            intentConfig: intentConfig
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }
    func testPaymentSheet_LPM_bancontact_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"bancontact\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["bancontact"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_sofort_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"sofort\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["sofort"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_sofort_setupIntent_customerSession() {
        stubSessions(
            fileMock: .elementsSessions_customerSessionsMobilePaymentElement_setupIntent_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"sofort\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubCustomers()
        stubConsumerSession()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .setup(currency: "eur", setupFutureUsage: .offSession),
                                                            paymentMethodTypes: ["sofort"],
                                                            confirmHandler: confirmHandler(_:_:_:),
                                                            requireCVCRecollection: false)
        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["sofort"],
            automaticPaymentMethods: false,
            useLink: false,
            intentConfig: intentConfig
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_sepaDebit_paymentIntent_customerSession() {
        stubSessions(
            fileMock: .elementsSessions_customerSessionsMobilePaymentElement_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"sepa_debit\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubCustomers()
        stubConsumerSession()
        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["sepa_debit"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_sepaDebit_setupIntent_customerSession() {
        stubSessions(
            fileMock: .elementsSessions_customerSessionsMobilePaymentElement_setupIntent_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"sepa_debit\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubCustomers()
        stubConsumerSession()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .setup(currency: "eur", setupFutureUsage: .offSession),
                                                            paymentMethodTypes: ["sepa_debit"],
                                                            confirmHandler: confirmHandler(_:_:_:),
                                                            requireCVCRecollection: false)
        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["sepa_debit"],
            automaticPaymentMethods: false,
            useLink: false,
            intentConfig: intentConfig
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_sepaDebit_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"sepa_debit\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["sepa_debit"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_eps_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"eps\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["eps"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_giropay_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"giropay\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["giropay"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_p24_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"p24\"",
                        "<currency>": "\"eur\"",
                    ]
                )
            }
        )
        stubPaymentMethods(stubRequestCallback: nil, fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            currency: "eur",
            override_payment_methods_types: ["p24"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_aubecs_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"au_becs_debit\"",
                        "<currency>": "\"aud\"",
                    ]
                )
            }
        )
        stubPaymentMethods(stubRequestCallback: nil, fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            currency: "aud",
            override_payment_methods_types: ["au_becs_debit"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_paypal_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"paypal\"",
                        "<currency>": "\"GBP\"",
                    ]
                )
            }
        )
        stubPaymentMethods(stubRequestCallback: nil, fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            currency: "gbp",
            override_payment_methods_types: ["paypal"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)
    }

    func testPaymentSheet_LPM_upi_only() {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"upi\"",
                        "<currency>": "\"inr\"",
                    ]
                )
            }
        )
        stubPaymentMethods(stubRequestCallback: nil, fileMock: .saved_payment_methods_200)
        stubCustomers()
        stubConsumerSession()

        preparePaymentSheet(
            currency: "inr",
            override_payment_methods_types: ["upi"],
            automaticPaymentMethods: false,
            useLink: false
        )
        presentPaymentSheet(darkMode: false)
        verify(paymentSheet.bottomSheetViewController.view!)

    }
}
