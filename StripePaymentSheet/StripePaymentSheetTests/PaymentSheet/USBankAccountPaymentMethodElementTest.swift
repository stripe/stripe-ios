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

@MainActor
final class USBankAccountPaymentMethodElementTest: XCTestCase {
    let window: UIWindow = UIWindow(frame: .init(x: 0, y: 0, width: 428, height: 926))

    func testPreservesPreviousCustomerInput() {
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        let form = makeForm(configuration: configuration, previousCustomerInput: nil)
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
        let regeneratedForm = makeForm(
            configuration: configuration,
            previousCustomerInput: intentConfirmParams
        )
        guard let regeneratedIntentConfirmParams = regeneratedForm.updateParams(params: IntentConfirmParams(type: .stripe(.USBankAccount))) else {
            XCTFail("Regenerated form failed to create params. Validation state: \(regeneratedForm.validationState) \n Form: \(regeneratedForm)")
            return
        }
        // Ensure checkbox remains selected
        XCTAssertTrue(regeneratedForm.getCheckboxElement(startingWith: "Save this account")!.isSelected)
        XCTAssertEqual(regeneratedIntentConfirmParams, intentConfirmParams)
    }

    func testBillingDetailsIncludesConfiguredDefaults() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .never
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.billingDetailsCollectionConfiguration.phone = .never
        configuration.billingDetailsCollectionConfiguration.address = .never
        configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod = true
        configuration.defaultBillingDetails.name = "Test Customer"
        configuration.defaultBillingDetails.email = "customer@example.com"
        configuration.defaultBillingDetails.phone = "+15555550100"
        configuration.defaultBillingDetails.address = .init(
            city: "Springfield",
            country: "US",
            line1: "123 Main Street",
            line2: "Apt 4",
            postalCode: "12345",
            state: "CA"
        )

        let form = makeForm(configuration: configuration, previousCustomerInput: nil)
        let billingDetails = form.billingDetails

        XCTAssertEqual(billingDetails.name, "Test Customer")
        XCTAssertEqual(billingDetails.email, "customer@example.com")
        XCTAssertEqual(billingDetails.phone, "+15555550100")
        XCTAssertEqual(billingDetails.address?.city, "Springfield")
        XCTAssertEqual(billingDetails.address?.country, "US")
        XCTAssertEqual(billingDetails.address?.line1, "123 Main Street")
        XCTAssertEqual(billingDetails.address?.line2, "Apt 4")
        XCTAssertEqual(billingDetails.address?.postalCode, "12345")
        XCTAssertEqual(billingDetails.address?.state, "CA")
    }

    private func makeForm(
        configuration: PaymentSheet.Configuration,
        previousCustomerInput: IntentConfirmParams?
    ) -> USBankAccountPaymentMethodElement {
        let intent: Intent = ._testPaymentIntent(paymentMethodTypes: [.USBankAccount])
        let formVC = PaymentMethodFormViewController(
            type: .stripe(.USBankAccount),
            intent: intent,
            elementsSession: ._testValue(intent: intent),
            previousCustomerInput: previousCustomerInput,
            formCache: .init(),
            configuration: configuration,
            paymentMethodOrientation: .vertical,
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
}

extension USBankAccountPaymentMethodElementTest: PaymentMethodFormViewControllerDelegate {
    func didUpdate(_ viewController: StripePaymentSheet.PaymentMethodFormViewController) {

    }

    func updateErrorLabel(for error: (any Error)?) {

    }
}
