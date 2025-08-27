//
//  PaymentSheetFormFactory+CardEmailPhoneFieldsTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 8/5/25.
//

import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI
@testable@_spi(STP) import StripeUICore

class PaymentSheetFormFactoryCardEmailPhoneFieldsTest: XCTestCase {
    let dummyAddressSpecProvider: AddressSpecProvider = {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
            "CA": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .province, zip: "", zipNameType: .pin),
        ]
        return specProvider
    }()

    // MARK: - Email/Phone field relocation tests

    func testCardFormWithEmailPhoneAlwaysAndAutomaticBilling_EmailPhoneInBillingAddress() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .automatic

        let factory = PaymentSheetFormFactory(
            intent: ._testValue(),
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(configuration),
            paymentMethod: .stripe(.card),
            addressSpecProvider: dummyAddressSpecProvider
        )

        let cardForm = factory.makeCard()

        // Verify card form structure - should have card section, billing address section with email/phone, no separate contact info section
        guard let containerElement = cardForm as? ContainerElement else {
            XCTFail("Expected ContainerElement")
            return
        }

        // Find the billing address section
        let billingAddressSectionWrapper = containerElement.elements.compactMap { element in
            element as? PaymentMethodElementWrapper<AddressSectionElement>
        }.first
        XCTAssertNotNil(billingAddressSectionWrapper, "Should have billing address section when address collection is .automatic")

        // Verify email and phone are included in the billing address section
        let billingAddressSection = billingAddressSectionWrapper?.element
        XCTAssertNotNil(billingAddressSection?.email, "Email field should be included in billing address section")
        XCTAssertNotNil(billingAddressSection?.phone, "Phone field should be included in billing address section")

        // Verify there's no separate contact information section
        let contactInfoSection = containerElement.elements.compactMap { element in
            element as? SectionElement
        }.first { section in
            section.title == String.Localized.contact_information
        }
        XCTAssertNil(contactInfoSection, "Should not have separate contact information section when billing address includes email/phone")
    }

    func testCardFormWithEmailPhoneAlwaysAndFullBilling_EmailPhoneInBillingAddress() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full

        let factory = PaymentSheetFormFactory(
            intent: ._testValue(),
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(configuration),
            paymentMethod: .stripe(.card),
            addressSpecProvider: dummyAddressSpecProvider
        )

        let cardForm = factory.makeCard()

        guard let containerElement = cardForm as? ContainerElement else {
            XCTFail("Expected ContainerElement")
            return
        }

        // Find the billing address section
        let billingAddressSectionWrapper = containerElement.elements.compactMap { element in
            element as? PaymentMethodElementWrapper<AddressSectionElement>
        }.first
        XCTAssertNotNil(billingAddressSectionWrapper, "Should have billing address section when address collection is .full")

        // Verify email and phone are included in the billing address section
        let billingAddressSection = billingAddressSectionWrapper?.element
        XCTAssertNotNil(billingAddressSection?.email, "Email field should be included in billing address section")
        XCTAssertNotNil(billingAddressSection?.phone, "Phone field should be included in billing address section")

        // Verify there's no separate contact information section
        let contactInfoSection = containerElement.elements.compactMap { element in
            element as? SectionElement
        }.first { section in
            section.title == String.Localized.contact_information
        }
        XCTAssertNil(contactInfoSection, "Should not have separate contact information section when billing address includes email/phone")
    }

    func testCardFormWithEmailPhoneAlwaysAndNeverBilling_EmailPhoneInContactInfo() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .never

        let factory = PaymentSheetFormFactory(
            intent: ._testValue(),
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(configuration),
            paymentMethod: .stripe(.card),
            addressSpecProvider: dummyAddressSpecProvider
        )

        let cardForm = factory.makeCard()

        guard let containerElement = cardForm as? ContainerElement else {
            XCTFail("Expected ContainerElement")
            return
        }

        // Verify there's no billing address section
        let billingAddressSectionWrapper = containerElement.elements.compactMap { element in
            element as? PaymentMethodElementWrapper<AddressSectionElement>
        }.first
        XCTAssertNil(billingAddressSectionWrapper, "Should not have billing address section when address collection is .never")

        // Verify there's a separate contact information section with email and phone
        let contactInfoSection = containerElement.elements.compactMap { element in
            element as? SectionElement
        }.first { section in
            section.title == String.Localized.contact_information
        }
        XCTAssertNotNil(contactInfoSection, "Should have separate contact information section when no billing address section")

        // Find email and phone elements in contact info section
        let emailElement = contactInfoSection?.elements.compactMap { element in
            element as? PaymentMethodElementWrapper<TextFieldElement>
        }.first { wrapper in
            wrapper.element.configuration.label == String.Localized.email
        }
        XCTAssertNotNil(emailElement, "Contact information section should contain email field")

        let phoneElement = contactInfoSection?.elements.compactMap { element in
            element as? PaymentMethodElementWrapper<PhoneNumberElement>
        }.first
        XCTAssertNotNil(phoneElement, "Contact information section should contain phone field")
    }

    func testCardFormWithOnlyEmailAlways_EmailInContactInfo() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .never
        configuration.billingDetailsCollectionConfiguration.address = .never

        let factory = PaymentSheetFormFactory(
            intent: ._testValue(),
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(configuration),
            paymentMethod: .stripe(.card),
            addressSpecProvider: dummyAddressSpecProvider
        )

        let cardForm = factory.makeCard()

        guard let containerElement = cardForm as? ContainerElement else {
            XCTFail("Expected ContainerElement")
            return
        }

        // Verify there's a separate contact information section with only email
        let contactInfoSection = containerElement.elements.compactMap { element in
            element as? SectionElement
        }.first { section in
            section.title == String.Localized.contact_information
        }
        XCTAssertNotNil(contactInfoSection, "Should have contact information section with email")

        // Should have exactly 1 element (email)
        XCTAssertEqual(contactInfoSection?.elements.count, 1, "Contact information section should have exactly 1 element (email)")

        let emailElement = contactInfoSection?.elements.first as? PaymentMethodElementWrapper<TextFieldElement>
        XCTAssertEqual(emailElement?.element.configuration.label, String.Localized.email, "Should be email field")
    }

    func testCardFormWithOnlyPhoneAlways_PhoneInContactInfo() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .never

        let factory = PaymentSheetFormFactory(
            intent: ._testValue(),
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(configuration),
            paymentMethod: .stripe(.card),
            addressSpecProvider: dummyAddressSpecProvider
        )

        let cardForm = factory.makeCard()

        guard let containerElement = cardForm as? ContainerElement else {
            XCTFail("Expected ContainerElement")
            return
        }

        // Verify there's a separate contact information section with only phone
        let contactInfoSection = containerElement.elements.compactMap { element in
            element as? SectionElement
        }.first { section in
            section.title == String.Localized.contact_information
        }
        XCTAssertNotNil(contactInfoSection, "Should have contact information section with phone")

        // Should have exactly 1 element (phone)
        XCTAssertEqual(contactInfoSection?.elements.count, 1, "Contact information section should have exactly 1 element (phone)")

        let phoneElement = contactInfoSection?.elements.first as? PaymentMethodElementWrapper<PhoneNumberElement>
        XCTAssertNotNil(phoneElement, "Should be phone field")
    }

    func testCardFormWithNeitherEmailNorPhone_NoContactInfo() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.billingDetailsCollectionConfiguration.phone = .never
        configuration.billingDetailsCollectionConfiguration.address = .never

        let factory = PaymentSheetFormFactory(
            intent: ._testValue(),
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(configuration),
            paymentMethod: .stripe(.card),
            addressSpecProvider: dummyAddressSpecProvider
        )

        let cardForm = factory.makeCard()

        guard let containerElement = cardForm as? ContainerElement else {
            XCTFail("Expected ContainerElement")
            return
        }

        // Verify there's no contact information section
        let contactInfoSection = containerElement.elements.compactMap { element in
            element as? SectionElement
        }.first { section in
            section.title == String.Localized.contact_information
        }
        XCTAssertNil(contactInfoSection, "Should not have contact information section when neither email nor phone are collected")
    }

    // MARK: - Parameter updates tests

    func testCardFormEmailPhoneInBillingAddress_UpdatesParams() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .automatic
        configuration.defaultBillingDetails.email = "test@example.com"
        configuration.defaultBillingDetails.phone = "+15555555555"
        configuration.defaultBillingDetails.address = .init(city: "Onnet", country: "US", postalCode: "12345", state: "CA")

        let factory = PaymentSheetFormFactory(
            intent: ._testValue(),
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(configuration),
            paymentMethod: .stripe(.card),
            addressSpecProvider: dummyAddressSpecProvider
        )

        guard let cardForm = factory.makeCard() as? ContainerElement else {
            XCTFail()
            return
        }

        // Find and fill card element
        let cardElement = cardForm.elements.compactMap { element in
            element as? CardSectionElement
        }.first
        cardElement?.panElement.setText("4242424242424242")
        cardElement?.expiryElement.setText("12/34")
        cardElement?.cvcElement.setText("123")

        // Needs to be valid to get billing details
        XCTAssertEqual(cardForm.validationState, .valid)

        let params = cardForm.updateParams(params: IntentConfirmParams(type: .stripe(.card)))

        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.email, "test@example.com")
        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.phone, "+15555555555")
    }

    func testCardFormEmailPhoneInContactInfo_UpdatesParams() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .never
        configuration.defaultBillingDetails.email = "contact@example.com"
        configuration.defaultBillingDetails.phone = "+16666666666"

        let factory = PaymentSheetFormFactory(
            intent: ._testValue(),
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(configuration),
            paymentMethod: .stripe(.card),
            addressSpecProvider: dummyAddressSpecProvider
        )

        guard let cardForm = factory.makeCard() as? ContainerElement else {
            XCTFail()
            return
        }

        // Find and fill card element
        let cardElement = cardForm.elements.compactMap { element in
            element as? CardSectionElement
        }.first
        cardElement?.panElement.setText("4242424242424242")
        cardElement?.expiryElement.setText("12/34")
        cardElement?.cvcElement.setText("123")

        let params = cardForm.updateParams(params: IntentConfirmParams(type: .stripe(.card)))

        // Needs to be valid to get billing details
        XCTAssertEqual(cardForm.validationState, .valid)

        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.email, "contact@example.com")
        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.phone, "+16666666666")
    }

    // MARK: - AddressSectionElement with email field tests

    func testMakeBillingAddressSectionWithEmailAndPhone() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "billing@test.com"
        configuration.defaultBillingDetails.phone = "+17777777777"
        configuration.defaultBillingDetails.address = .init(city: "Onnet", country: "US", line1: "Twoson", postalCode: "12345", state: "CA")

        let factory = PaymentSheetFormFactory(
            intent: ._testValue(),
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(configuration),
            paymentMethod: .stripe(.card),
            addressSpecProvider: dummyAddressSpecProvider
        )

        let billingAddressSection = factory.makeBillingAddressSection(
            collectionMode: .autoCompletable,
            countries: nil,
            includeEmail: true,
            includePhone: true
        )

        // Verify email and phone fields are present
        XCTAssertNotNil(billingAddressSection.element.email, "Billing address section should have email field")
        XCTAssertNotNil(billingAddressSection.element.phone, "Billing address section should have phone field")

        // Verify default values are set
        XCTAssertEqual(billingAddressSection.element.email?.text, "billing@test.com")
        XCTAssertEqual(billingAddressSection.element.phone?.phoneNumber?.string(as: .e164), "+17777777777")

        // Verify params updates include email and phone
        let params = billingAddressSection.updateParams(params: IntentConfirmParams(type: .stripe(.card)))
        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.email, "billing@test.com")
        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.phone, "+17777777777")
    }

    func testMakeBillingAddressSectionWithoutEmailAndPhone() {
        let factory = PaymentSheetFormFactory(
            intent: ._testValue(),
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(PaymentSheet.Configuration()),
            paymentMethod: .stripe(.card),
            addressSpecProvider: dummyAddressSpecProvider
        )

        let billingAddressSection = factory.makeBillingAddressSection(
            collectionMode: .autoCompletable,
            countries: nil,
            includeEmail: false,
            includePhone: false
        )

        // Verify email and phone fields are not present
        XCTAssertNil(billingAddressSection.element.email, "Billing address section should not have email field")
        XCTAssertNil(billingAddressSection.element.phone, "Billing address section should not have phone field")
    }

    // MARK: - Validation state tests

    func testCardFormWithEmailPhoneInBillingAddress_ValidationState() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .automatic

        let factory = PaymentSheetFormFactory(
            intent: ._testValue(),
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(configuration),
            paymentMethod: .stripe(.card),
            addressSpecProvider: dummyAddressSpecProvider
        )

        let cardForm = factory.makeCard()

        // Initially invalid (no card number, email, phone, etc.)
        XCTAssertNotEqual(cardForm.validationState, .valid)

        guard let containerElement = cardForm as? ContainerElement,
              let billingAddressSectionWrapper = containerElement.elements.compactMap({ $0 as? PaymentMethodElementWrapper<AddressSectionElement> }).first else {
            XCTFail("Could not find billing address section")
            return
        }

        // Set valid email and phone
        billingAddressSectionWrapper.element.email?.setText("valid@example.com")
        billingAddressSectionWrapper.element.phone?.textFieldElement.setText("5555555555")

        // And a postal code
        billingAddressSectionWrapper.element.postalCode?.setText("12345")

        // Find and fill card element
        let cardElement = containerElement.elements.compactMap { element in
            element as? CardSectionElement
        }.first
        cardElement?.panElement.setText("4242424242424242")
        cardElement?.expiryElement.setText("12/34")
        cardElement?.cvcElement.setText("123")

        // Now should be valid
        XCTAssertEqual(cardForm.validationState, .valid)
    }
}
