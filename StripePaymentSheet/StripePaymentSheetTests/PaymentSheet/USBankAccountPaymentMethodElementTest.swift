//
//  USBankAccountPaymentMethodElementTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 10/2/24.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI
@testable@_spi(STP) import StripeUICore
import XCTest

final class USBankAccountPaymentMethodElementTest: XCTestCase {
    let window: UIWindow = UIWindow(frame: .init(x: 0, y: 0, width: 428, height: 926))

    func testPreservesPreviousCustomerInput() {
        func makeForm(previousCustomerInput: IntentConfirmParams?) -> USBankAccountPaymentMethodElement {
            let intent: Intent = ._testPaymentIntent(paymentMethodTypes: [.USBankAccount])
            let formVC = PaymentMethodFormViewController(
                type: .stripe(.USBankAccount),
                intent: intent,
                elementsSession: ._testValue(intent: intent),
                previousCustomerInput: previousCustomerInput,
                formCache: .init(),
                configuration: configuration,
                headerView: nil,
                analyticsHelper: ._testValue(),
                delegate: self
            )

            // Add to window to avoid layout errors due to zero size and presentation errors
            window.rootViewController = formVC

            // Simulate view appearance. This makes SimpleMandateElement mark its mandate as having been displayed.
            formVC.viewDidAppear(false)
            return formVC.form as! USBankAccountPaymentMethodElement
        }
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        let form = makeForm(previousCustomerInput: nil)
        let checkbox = form.getCheckboxElement(startingWith: "Save this account")!
        XCTAssertNotNil(checkbox) // Checkbox should appear since this is a PI w/ customer
        XCTAssertNil(form.mandateString) // Mandate should not appear until linked bank is set
        form.getTextFieldElement("Full name").setText("Name")
        form.getTextFieldElement("Email").setText("foo@bar.com")
        // Simulate customer setting up a linked bank account
        form.linkedBank = FinancialConnectionsLinkedBank(sessionId: "123", accountId: "123", displayName: "Success", bankName: "StripeBank", last4: "6789", instantlyVerified: true)
        XCTAssertEqual(form.getAllUnwrappedSubElements().count, 10)
        XCTAssertNotNil(form.mandateString)
        checkbox.isSelected = true

        // Generate params from the form
        guard let intentConfirmParams = form.updateParams(params: IntentConfirmParams(type: .stripe(.USBankAccount))) else {
            XCTFail("Form failed to create params. Validation state: \(form.validationState) \n Form: \(form)")
            return
        }

        // Re-generate the form and validate that it carries over all previous customer input
        let regeneratedForm = makeForm(previousCustomerInput: intentConfirmParams)
        guard let regeneratedIntentConfirmParams = regeneratedForm.updateParams(params: IntentConfirmParams(type: .stripe(.USBankAccount))) else {
            XCTFail("Regenerated form failed to create params. Validation state: \(regeneratedForm.validationState) \n Form: \(regeneratedForm)")
            return
        }
        // Ensure checkbox remains selected
        XCTAssertTrue(regeneratedForm.getCheckboxElement(startingWith: "Save this account")!.isSelected)
        XCTAssertEqual(regeneratedIntentConfirmParams, intentConfirmParams)
    }
}

extension USBankAccountPaymentMethodElementTest: PaymentMethodFormViewControllerDelegate {
    func didUpdate(_ viewController: StripePaymentSheet.PaymentMethodFormViewController) {

    }

    func updateErrorLabel(for error: (any Error)?) {

    }
}
