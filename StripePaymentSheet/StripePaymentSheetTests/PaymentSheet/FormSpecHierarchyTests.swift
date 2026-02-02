//
//  FormSpecHierarchyTests.swift
//  StripePaymentSheetTests
//
//  Tests that verify the structure of forms generated from form specs and explicit form builders.
//  These tests codify the expected element hierarchy for each payment method.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripeUICore
import XCTest

/// Tests for forms generated from form specs (JSON-defined)
class FormSpecHierarchyTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Load form specs
        let formSpecExpectation = expectation(description: "Load form specs")
        FormSpecProvider.shared.load { _ in
            formSpecExpectation.fulfill()
        }
        // Load address specs (needed for country dropdowns)
        let addressSpecExpectation = expectation(description: "Load address specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            addressSpecExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    // MARK: - Factory Helpers

    /// Creates a factory with minimal billing details collection for testing form spec structure
    private func makeFactory(for paymentMethodType: STPPaymentMethodType) -> PaymentSheetFormFactory {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .never
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.billingDetailsCollectionConfiguration.phone = .never
        configuration.billingDetailsCollectionConfiguration.address = .never

        let intent = Intent._testPaymentIntent(paymentMethodTypes: [paymentMethodType])
        return PaymentSheetFormFactory(
            intent: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: .paymentElement(configuration),
            paymentMethod: .stripe(paymentMethodType)
        )
    }

    /// Creates a form from a spec and returns it
    private func makeFormFromSpec(for specType: String, factory: PaymentSheetFormFactory) -> FormElement? {
        guard let spec = FormSpecProvider.shared.formSpec(for: specType) else {
            return nil
        }
        return factory.makeFormElementFromSpec(spec: spec).element
    }

    // MARK: - Form Spec Tests

    func testAffirmFormHierarchy() throws {
        let factory = makeFactory(for: .affirm)
        let form = try XCTUnwrap(makeFormFromSpec(for: "affirm", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SubtitleElement")
        ])

        XCTAssertEqual(actual, expected)
    }

    func testAfterpayFormHierarchy() throws {
        let factory = makeFactory(for: .afterpayClearpay)
        let form = try XCTUnwrap(makeFormFromSpec(for: "afterpay_clearpay", factory: factory))

        let actual = form.toHierarchyNode()
        // Afterpay has a header - the form spec requires name/email but we disabled collection
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SubtitleElement")
        ])

        XCTAssertEqual(actual, expected)
    }

    func testKlarnaFormHierarchy() throws {
        let factory = makeFactory(for: .klarna)
        let form = try XCTUnwrap(makeFormFromSpec(for: "klarna", factory: factory))

        let actual = form.toHierarchyNode()
        // Klarna has header + country dropdown
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SubtitleElement"),
            FormHierarchyNode(type: "SectionElement", children: [
                FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "235", "label": "Country or region"])
            ]),
        ])

        XCTAssertEqual(actual, expected)
    }

    func testEPSFormHierarchy() throws {
        let factory = makeFactory(for: .EPS)
        let form = try XCTUnwrap(makeFormFromSpec(for: "eps", factory: factory))

        let actual = form.toHierarchyNode()
        // EPS has a bank dropdown
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SectionElement", children: [
                FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "27", "label": "EPS Bank"])
            ]),
        ])

        XCTAssertEqual(actual, expected)
    }

    func testP24FormHierarchy() throws {
        let factory = makeFactory(for: .przelewy24)
        let form = try XCTUnwrap(makeFormFromSpec(for: "p24", factory: factory))

        let actual = form.toHierarchyNode()
        // P24 has a bank dropdown
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SectionElement", children: [
                FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "23", "label": "Przelewy24 Bank"])
            ]),
        ])

        XCTAssertEqual(actual, expected)
    }

    func testPayPalFormHierarchy() throws {
        let factory = makeFactory(for: .payPal)
        let form = try XCTUnwrap(makeFormFromSpec(for: "paypal", factory: factory))

        let actual = form.toHierarchyNode()
        // PayPal has empty fields in spec
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testAUBECSDebitFormHierarchy() throws {
        let factory = makeFactory(for: .AUBECSDebit)
        let form = try XCTUnwrap(makeFormFromSpec(for: "au_becs_debit", factory: factory))

        let actual = form.toHierarchyNode()
        // AU BECS has BSB section, account number section, plus legal terms mandate
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SectionElement", children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "BSB number"])
            ]),
            FormHierarchyNode(type: "SectionElement", children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Account number"])
            ]),
            FormHierarchyNode(type: "StaticElement", properties: ["viewType": "AUBECSLegalTermsView"]),
        ])

        XCTAssertEqual(actual, expected)
    }

    func testRevolutPayFormHierarchy() throws {
        let factory = makeFactory(for: .revolutPay)
        let form = try XCTUnwrap(makeFormFromSpec(for: "revolut_pay", factory: factory))

        let actual = form.toHierarchyNode()
        // Revolut Pay has empty fields
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testAmazonPayFormHierarchy() throws {
        let factory = makeFactory(for: .amazonPay)
        let form = try XCTUnwrap(makeFormFromSpec(for: "amazon_pay", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testAlmaFormHierarchy() throws {
        let factory = makeFactory(for: .alma)
        let form = try XCTUnwrap(makeFormFromSpec(for: "alma", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testSunbitFormHierarchy() throws {
        let factory = makeFactory(for: .sunbit)
        let form = try XCTUnwrap(makeFormFromSpec(for: "sunbit", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testBillieFormHierarchy() throws {
        let factory = makeFactory(for: .billie)
        let form = try XCTUnwrap(makeFormFromSpec(for: "billie", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testSatispayFormHierarchy() throws {
        let factory = makeFactory(for: .satispay)
        let form = try XCTUnwrap(makeFormFromSpec(for: "satispay", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testCryptoFormHierarchy() throws {
        let factory = makeFactory(for: .crypto)
        let form = try XCTUnwrap(makeFormFromSpec(for: "crypto", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testMobilePayFormHierarchy() throws {
        let factory = makeFactory(for: .mobilePay)
        let form = try XCTUnwrap(makeFormFromSpec(for: "mobilepay", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testZipFormHierarchy() throws {
        let factory = makeFactory(for: .zip)
        let form = try XCTUnwrap(makeFormFromSpec(for: "zip", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testCashAppFormHierarchy() throws {
        let factory = makeFactory(for: .cashApp)
        let form = try XCTUnwrap(makeFormFromSpec(for: "cashapp", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testGrabPayFormHierarchy() throws {
        let factory = makeFactory(for: .grabPay)
        let form = try XCTUnwrap(makeFormFromSpec(for: "grabpay", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testFPXFormHierarchy() throws {
        let factory = makeFactory(for: .FPX)
        let form = try XCTUnwrap(makeFormFromSpec(for: "fpx", factory: factory))

        let actual = form.toHierarchyNode()
        // FPX has a bank dropdown
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SectionElement", children: [
                FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "18", "label": "FPX Bank"])
            ]),
        ])

        XCTAssertEqual(actual, expected)
    }

    func testAlipayFormHierarchy() throws {
        let factory = makeFactory(for: .alipay)
        let form = try XCTUnwrap(makeFormFromSpec(for: "alipay", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testPayNowFormHierarchy() throws {
        let factory = makeFactory(for: .paynow)
        let form = try XCTUnwrap(makeFormFromSpec(for: "paynow", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testPromptPayFormHierarchy() throws {
        let factory = makeFactory(for: .promptPay)
        let form = try XCTUnwrap(makeFormFromSpec(for: "promptpay", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testTwintFormHierarchy() throws {
        let factory = makeFactory(for: .twint)
        let form = try XCTUnwrap(makeFormFromSpec(for: "twint", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    func testMultibancoFormHierarchy() throws {
        let factory = makeFactory(for: .multibanco)
        let form = try XCTUnwrap(makeFormFromSpec(for: "multibanco", factory: factory))

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }
}

// MARK: - Explicit Form Tests

/// Tests for forms that are explicitly built in PaymentSheetFormFactory (not from specs)
class ExplicitFormHierarchyTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let formSpecExpectation = expectation(description: "Load form specs")
        FormSpecProvider.shared.load { _ in
            formSpecExpectation.fulfill()
        }
        let addressSpecExpectation = expectation(description: "Load address specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            addressSpecExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    // MARK: - Factory Helpers

    private func makeFactory(
        for paymentMethodType: STPPaymentMethodType,
        configuration: PaymentSheet.Configuration = PaymentSheet.Configuration()
    ) -> PaymentSheetFormFactory {
        var config = configuration
        // Disable all optional billing details by default unless already set
        if config.billingDetailsCollectionConfiguration.name == .automatic {
            config.billingDetailsCollectionConfiguration.name = .never
        }
        if config.billingDetailsCollectionConfiguration.email == .automatic {
            config.billingDetailsCollectionConfiguration.email = .never
        }
        if config.billingDetailsCollectionConfiguration.phone == .automatic {
            config.billingDetailsCollectionConfiguration.phone = .never
        }
        if config.billingDetailsCollectionConfiguration.address == .automatic {
            config.billingDetailsCollectionConfiguration.address = .never
        }

        let intent = Intent._testPaymentIntent(paymentMethodTypes: [paymentMethodType])
        return PaymentSheetFormFactory(
            intent: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: .paymentElement(config),
            paymentMethod: .stripe(paymentMethodType)
        )
    }

    // MARK: - Card Form

    func testCardFormHierarchy() throws {
        let factory = makeFactory(for: .card)
        let form = factory.make()

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "CardSectionElement", children: [
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Card number"]),
                    FormHierarchyNode(type: "MultiElementRow", children: [
                        FormHierarchyNode(type: "TextFieldElement", properties: ["label": "MM / YY"]),
                        FormHierarchyNode(type: "TextFieldElement", properties: ["label": "CVC"]),
                    ]),
                ]),
            ]),
        ])

        XCTAssertEqual(actual, expected)
    }

    // MARK: - iDEAL Form (uses spec but has explicit builder)

    func testIDEALFormHierarchy() throws {
        let factory = makeFactory(for: .iDEAL)
        let form = factory.make()

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SectionElement", children: [
                FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "13", "label": "iDEAL Bank"])
            ]),
        ])

        XCTAssertEqual(actual, expected)
    }

    // MARK: - SEPA Debit Form (explicit builder)

    func testSEPADebitFormHierarchy() throws {
        var config = PaymentSheet.Configuration()
        config.billingDetailsCollectionConfiguration.name = .always
        config.billingDetailsCollectionConfiguration.email = .always

        let factory = makeFactory(for: .SEPADebit, configuration: config)
        let form = factory.make()

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
            ]),
            FormHierarchyNode(type: "SectionElement", children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "IBAN"])
            ]),
            FormHierarchyNode(type: "SimpleMandateElement", properties: ["text": "By providing your payment information and confirmi..."]),
        ])

        XCTAssertEqual(actual, expected)
    }

    // MARK: - Bancontact Form (explicit builder)

    func testBancontactFormHierarchy() throws {
        var config = PaymentSheet.Configuration()
        config.billingDetailsCollectionConfiguration.name = .always

        let factory = makeFactory(for: .bancontact, configuration: config)
        let form = factory.make()

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SectionElement", children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"])
            ]),
        ])

        XCTAssertEqual(actual, expected)
    }

    // MARK: - Bacs Debit Form (explicit builder)

    func testBacsDebitFormHierarchy() throws {
        var config = PaymentSheet.Configuration()
        config.billingDetailsCollectionConfiguration.name = .always
        config.billingDetailsCollectionConfiguration.email = .always
        config.billingDetailsCollectionConfiguration.address = .full

        let factory = makeFactory(for: .bacsDebit, configuration: config)
        let form = factory.make()

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
            ]),
            FormHierarchyNode(type: "SectionElement", properties: ["title": "Bank account"], children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Sort code"]),
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Account number"]),
            ]),
            FormHierarchyNode(type: "AddressSectionElement", children: [
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Billing address"], children: [
                    FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "235", "label": "Country or region"]),
                    FormHierarchyNode(type: "DummyAddressLine"),
                ]),
                FormHierarchyNode(type: "CheckboxElement", properties: ["label": "Billing address is same as shipping"]),
            ]),
            FormHierarchyNode(type: "CheckboxElement", properties: ["label": "I understand that Stripe will be collecting Direct Debits on behalf of StripePaymentSheetTestHostApp and confirm that I am the account holder and the only person required to authorise debits from this account."]),
        ])

        XCTAssertEqual(actual, expected)
    }

    // MARK: - US Bank Account Form (explicit builder)

    func testUSBankAccountFormHierarchy() throws {
        var config = PaymentSheet.Configuration()
        config.billingDetailsCollectionConfiguration.name = .always
        config.billingDetailsCollectionConfiguration.email = .always

        let factory = makeFactory(for: .USBankAccount, configuration: config)
        let form = factory.make()

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "USBankAccountPaymentMethodElement", children: [
            FormHierarchyNode(type: "FormElement", children: [
                FormHierarchyNode(type: "SubtitleElement"),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"])
                ]),
                FormHierarchyNode(type: "SectionElement", children: [
                    FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"])
                ]),
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Bank account"], children: [
                    FormHierarchyNode(type: "StaticElement", properties: ["viewType": "BankAccountInfoView"])
                ]),
            ]),
        ])

        XCTAssertEqual(actual, expected)
    }

    // MARK: - BLIK Form (explicit builder)

    func testBLIKFormHierarchy() throws {
        let factory = makeFactory(for: .blik)
        let form = factory.make()

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SectionElement", children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "BLIK code"])
            ]),
        ])

        XCTAssertEqual(actual, expected)
    }

    // MARK: - OXXO Form (explicit builder)

    func testOXXOFormHierarchy() throws {
        var config = PaymentSheet.Configuration()
        config.billingDetailsCollectionConfiguration.name = .always
        config.billingDetailsCollectionConfiguration.email = .always

        let factory = makeFactory(for: .OXXO, configuration: config)
        let form = factory.make()

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
            ]),
        ])

        XCTAssertEqual(actual, expected)
    }

    // MARK: - Konbini Form (explicit builder)

    func testKonbiniFormHierarchy() throws {
        var config = PaymentSheet.Configuration()
        config.billingDetailsCollectionConfiguration.name = .always
        config.billingDetailsCollectionConfiguration.email = .always

        let factory = makeFactory(for: .konbini, configuration: config)
        let form = factory.make()

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
            ]),
            FormHierarchyNode(type: "SectionElement", children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Phone number"])
            ]),
        ])

        XCTAssertEqual(actual, expected)
    }

    // MARK: - Boleto Form (explicit builder)

    func testBoletoFormHierarchy() throws {
        var config = PaymentSheet.Configuration()
        config.billingDetailsCollectionConfiguration.name = .always
        config.billingDetailsCollectionConfiguration.email = .always
        config.billingDetailsCollectionConfiguration.address = .full

        let factory = makeFactory(for: .boleto, configuration: config)
        let form = factory.make()

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SectionElement", properties: ["title": "Contact information"], children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Full name"]),
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "Email"]),
            ]),
            FormHierarchyNode(type: "SectionElement", children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "CPF/CPNJ"])
            ]),
            FormHierarchyNode(type: "AddressSectionElement", children: [
                FormHierarchyNode(type: "SectionElement", properties: ["title": "Billing address"], children: [
                    FormHierarchyNode(type: "DropdownFieldElement", properties: ["itemCount": "1", "label": "Country or region"]),
                    FormHierarchyNode(type: "DummyAddressLine"),
                ]),
                FormHierarchyNode(type: "CheckboxElement", properties: ["label": "Billing address is same as shipping"]),
            ]),
        ])

        XCTAssertEqual(actual, expected)
    }

    // MARK: - Swish Form (explicit builder)

    func testSwishFormHierarchy() throws {
        let factory = makeFactory(for: .swish)
        let form = factory.make()

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement")

        XCTAssertEqual(actual, expected)
    }

    // MARK: - UPI Form (explicit builder)

    func testUPIFormHierarchy() throws {
        let factory = makeFactory(for: .UPI)
        let form = factory.make()

        let actual = form.toHierarchyNode()
        let expected = FormHierarchyNode(type: "FormElement", children: [
            FormHierarchyNode(type: "SubtitleElement"),
            FormHierarchyNode(type: "SectionElement", children: [
                FormHierarchyNode(type: "TextFieldElement", properties: ["label": "UPI ID"])
            ]),
        ])

        XCTAssertEqual(actual, expected)
    }
}
