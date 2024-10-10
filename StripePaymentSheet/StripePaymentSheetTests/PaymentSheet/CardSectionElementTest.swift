//
//  CardSectionElementTest.swift
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

@MainActor
final class CardSectionElementTest: XCTestCase {
    let window: UIWindow = UIWindow(frame: .init(x: 0, y: 0, width: 428, height: 926))

    func testLinkSignupPreservesPreviousCustomerInput() async {
        await PaymentSheetLoader.loadMiscellaneousSingletons()
        func makeForm(previousCustomerInput: IntentConfirmParams?) -> PaymentMethodElement {
            let intent: Intent = ._testPaymentIntent(paymentMethodTypes: [.card])
            let formVC = PaymentMethodFormViewController(
                type: .stripe(.card),
                intent: intent,
                elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: true),
                previousCustomerInput: previousCustomerInput,
                formCache: .init(),
                configuration: .init(),
                headerView: nil,
                analyticsHelper: ._testValue(),
                delegate: self
            )

            // Add to window to avoid layout errors due to zero size and presentation errors
            window.rootViewController = formVC

            // Simulate view appearance. This makes SimpleMandateElement mark its mandate as having been displayed.
            formVC.viewDidAppear(false)
            return formVC.form
        }
        let form = makeForm(previousCustomerInput: nil)
        let linkInlineSignupElement: LinkInlineSignupElement = form.getElement()!
        let linkInlineView = linkInlineSignupElement.signupView
        XCTAssertNotNil(linkInlineView.checkboxElement) // Checkbox should appear since this is a PI w/o customer
        form.getTextFieldElement("Card number")?.setText("4242424242424242")
        form.getTextFieldElement("MM / YY").setText("1232")
        form.getTextFieldElement("CVC").setText("123")
        form.getTextFieldElement("ZIP").setText("65432")

        // Simulate selecting checkbox
        linkInlineView.checkboxElement.isChecked = true
        linkInlineView.checkboxElement.didToggleCheckbox()

        // Set the email & phone number
        let email = "\(UUID().uuidString)@foo.com"
        linkInlineView.emailElement.emailAddressElement.setText(email)
        linkInlineView.phoneNumberElement.countryDropdownElement.setRawData("GB")
        linkInlineView.phoneNumberElement.textFieldElement.setText("1234567890")
        linkInlineView.nameElement.setText("John Doe")

        // Generate params from the form
        guard let intentConfirmParams = form.updateParams(params: IntentConfirmParams(type: .stripe(.card))) else {
            XCTFail("Form failed to create params. Validation state: \(form.validationState) \n Form: \(form)")
            return
        }

        // Re-generate the form and validate that it carries over all previous customer input
        let regeneratedForm = makeForm(previousCustomerInput: intentConfirmParams)
        let regeneratedLinkInlineSignupElement: LinkInlineSignupElement = regeneratedForm.getElement()!
        let regeneratedLinkInlineView = linkInlineSignupElement.signupView
        guard let regeneratedIntentConfirmParams = regeneratedForm.updateParams(params: IntentConfirmParams(type: .stripe(.card))) else {
            XCTFail("Regenerated form failed to create params. Validation state: \(regeneratedForm.validationState) \n Form: \(regeneratedForm)")
            return
        }
        XCTAssertEqual(regeneratedIntentConfirmParams, intentConfirmParams)
        XCTAssertTrue(regeneratedLinkInlineSignupElement.isChecked)
        XCTAssertEqual(regeneratedLinkInlineView.emailElement.emailAddressString, email)
        XCTAssertEqual(regeneratedLinkInlineView.nameElement.text, "John Doe")
        XCTAssertEqual(regeneratedLinkInlineView.phoneNumberElement.phoneNumber, PhoneNumber(number: "1234567890", countryCode: "GB"))
    }
}

extension CardSectionElementTest: PaymentMethodFormViewControllerDelegate {
    func didUpdate(_ viewController: StripePaymentSheet.PaymentMethodFormViewController) {

    }

    func updateErrorLabel(for error: (any Error)?) {

    }
}
