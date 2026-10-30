// Copyright © 2026 Stripe, Inc. All rights reserved.

@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
@testable @_spi(InternalOnlyAPI) import StripeUICore
import XCTest

@MainActor
class PaytoTests: XCTestCase {
    private func makeForm(intent: Intent? = nil, configuration: PaymentSheet.Configuration = .init(), previous: IntentConfirmParams? = nil) -> PaymentMethodElement {
        let form = PaymentSheetFormFactory(
            intent: intent ?? ._testPaymentIntent(paymentMethodTypes: [.payto]),
            elementsSession: ._testValue(paymentMethodTypes: ["payto"]),
            configuration: .paymentElement(configuration),
            paymentMethod: .stripe(.payto),
            previousCustomerInput: previous
        ).make()
        form.getAllUnwrappedSubElements().compactMap { $0 as? SimpleMandateElement }.forEach { $0.mandateTextView.viewDidAppear = true }
        return form
    }

    func testBankAccountValidationAndRestoration() throws {
        let form = makeForm()
        XCTAssertNil(form.updateParams(params: .init(type: .stripe(.payto))))
        form.getTextFieldElement("Full name").setText("Jane Smith")
        form.getTextFieldElement("BSB number").setText("000000")
        XCTAssertNil(form.updateParams(params: .init(type: .stripe(.payto))))
        form.getTextFieldElement("Account number").setText("000123456")
        let params = try XCTUnwrap(form.updateParams(params: .init(type: .stripe(.payto))))
        XCTAssertEqual(params.paymentMethodParams.additionalAPIParameters["payto[bsb_number]"] as? String, "000000")
        XCTAssertEqual(params.paymentMethodParams.additionalAPIParameters["payto[account_number]"] as? String, "000123456")
        XCTAssertNil(params.paymentMethodParams.additionalAPIParameters["payto[pay_id]"])
        let restored = try XCTUnwrap(makeForm(previous: params).updateParams(params: .init(type: .stripe(.payto))))
        XCTAssertEqual(restored, params)
    }

    func testSwitchingEntryMethodsOnlySubmitsVisibleFields() throws {
        let form = makeForm()
        form.getTextFieldElement("Full name").setText("Jane Smith")
        form.getTextFieldElement("BSB number").setText("000000")
        form.getTextFieldElement("Account number").setText("000123456")
        let params = try XCTUnwrap(form.updateParams(params: .init(type: .stripe(.payto))))
        let method: DropdownFieldElement = form.getDropdownFieldElement(String.Localized.payto_payment_details)
        method.selectedIndex = 1
        method.didUpdate?(1)
        XCTAssertNil(form.updateParams(params: .init(type: .stripe(.payto))))
        form.getTextFieldElement("PayID").setText("jane@example.com")
        XCTAssertNil(form.updateParams(params: .init(type: .stripe(.payto))))
        form.getTextFieldElement("Email").setText("jane@example.com")
        let payIDParams = try XCTUnwrap(form.updateParams(params: params))
        XCTAssertEqual(payIDParams.paymentMethodParams.additionalAPIParameters["payto[pay_id]"] as? String, "jane@example.com")
        XCTAssertNil(payIDParams.paymentMethodParams.additionalAPIParameters["payto[account_number]"])
        XCTAssertNil(payIDParams.paymentMethodParams.additionalAPIParameters["payto[bsb_number]"])
        let restored = try XCTUnwrap(makeForm(previous: payIDParams).updateParams(params: .init(type: .stripe(.payto))))
        XCTAssertEqual(restored, payIDParams)
        method.selectedIndex = 0
        method.didUpdate?(0)
        let bankParams = try XCTUnwrap(form.updateParams(params: payIDParams))
        XCTAssertNil(bankParams.paymentMethodParams.additionalAPIParameters["payto[pay_id]"])
        XCTAssertEqual(bankParams.paymentMethodParams.additionalAPIParameters["payto[account_number]"] as? String, "000123456")
    }

    func testPayIDValidation() {
        let form = makeForm()
        let field: TextFieldElement = form.getTextFieldElement("PayID")
        for value in ["jane@example.com", "0400 000 000", "400000000", "+61400000000", "(+61) 400-000-000", "+1 648 694 3210", " jane@example.com "] {
            field.setText(value)
            guard case .valid = field.validationState else {
                XCTFail("Expected a valid PayID: \(value)")
                continue
            }
        }
        for value in ["", "not-an-email", "123", "person@", "+61abc400000000", "040000000000000000000", "+614000000000000000000", "++61400000000", "+6100"] {
            field.setText(value)
            guard case .invalid = field.validationState else {
                XCTFail("Expected an invalid PayID: \(value)")
                continue
            }
        }
    }

    func testAvailabilityAndMandatesForEachIntentType() {
        let intents: [Intent] = [
            ._testPaymentIntent(paymentMethodTypes: [.payto]),
            ._testPaymentIntent(paymentMethodTypes: [.payto], setupFutureUsage: .offSession),
            ._testSetupIntent(paymentMethodTypes: [.payto]),
        ]
        for (index, intent) in intents.enumerated() {
            XCTAssertEqual(PaymentSheet.PaymentMethodType.supportsAdding(paymentMethod: .payto, configuration: PaymentSheet.Configuration(), intent: intent, elementsSession: ._testValue(intent: intent)), .supported)
            let mandates = makeForm(intent: intent).getAllUnwrappedSubElements().compactMap { $0 as? SimpleMandateElement }
            XCTAssertEqual(mandates.count, index == 0 ? 1 : 2)
        }
    }

    func testPollingConfiguration() {
        let model = PollingViewModel(paymentMethodType: .payto)
        XCTAssertEqual(model.initialPollDelay, 5)
        XCTAssertEqual(model.cancellationCheckTimeout, 3)
        XCTAssertEqual(model.retryInterval, 1)
        XCTAssertEqual(model.deadline.timeIntervalSinceNow, 30 * 60, accuracy: 0.5)
        XCTAssertTrue(model.showsCountdown)
        XCTAssertEqual(model.CTA, .Localized.payto_confirm_payment)
    }

    func testNextActionDecoding() {
        XCTAssertEqual(STPIntentAction.decodedObject(fromAPIResponse: ["type": "payto_await_authorization"])?.type, .paytoAwaitAuthorization)
        XCTAssertEqual(STPIntentActionType(string: "PAYTO_AWAIT_AUTHORIZATION"), .paytoAwaitAuthorization)
        XCTAssertEqual(STPIntentActionType.paytoAwaitAuthorization.stringValue, "payto_await_authorization")
    }

    func testPaymentMethodDecodingAndEncoding() throws {
        let method = try XCTUnwrap(STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_payto", "type": "payto", "created": 123, "livemode": false,
            "payto": ["bsb_number": "000000", "last4": "3456", "fingerprint": "fingerprint", "pay_id": "jane@example.com"],
        ]))
        XCTAssertEqual(method.type, .payto)
        XCTAssertEqual(method.payto?.bsbNumber, "000000")
        XCTAssertEqual(method.payto?.last4, "3456")
        XCTAssertEqual(method.payto?.payId, "jane@example.com")
        let details = STPPaymentMethodPaytoParams()
        details.bsbNumber = "000000"
        details.accountNumber = "000123456"
        let params = STPPaymentMethodParams(payto: details, billingDetails: nil, metadata: nil)
        let encoded = STPFormEncoder.dictionary(forObject: params)
        XCTAssertEqual(encoded["type"] as? String, "payto")
        XCTAssertEqual((encoded["payto"] as? [String: Any])?["bsb_number"] as? String, "000000")
        XCTAssertEqual((encoded["payto"] as? [String: Any])?["account_number"] as? String, "000123456")
        XCTAssertNotNil(STPPaymentIntentConfirmParams.mandateDataIfRequired(for: .payto))
        XCTAssertNotNil(STPSetupIntentConfirmParams.mandateDataIfRequired(for: .payto))
    }
}
