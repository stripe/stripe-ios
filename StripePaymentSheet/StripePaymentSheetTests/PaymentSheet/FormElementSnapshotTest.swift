//
//  FormElementSnapshotTest.swift
//  StripeUICoreTests
//
//  Created by Yuki Tokuhiro on 9/4/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
@_spi(STP) @_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore

// These are in StripePaymentSheet instead of StripeUICore so that we can test using PaymentSheet.Appearance rather than ElementsAppearance.
// @iOS26
final class FormElementSnapshotTest: STPSnapshotTestCase {
    var appearance = PaymentSheet.Appearance().applyingLiquidGlassIfPossible()
    var theme: ElementsAppearance {
        return appearance.asElementsTheme
    }

    func testDefaultTheme() {
        let formElement = makeExampleFormElement()
        verify(formElement)
    }

    // MARK: - Helpers

    func makeExampleFormElement() -> FormElement {
        // Make every element we know about
        let addressSectionElement = AddressSectionElement.makeExample(theme: theme)
        let dropdownField = DropdownFieldElement.makeExample(theme: theme)
        let phoneNumberField = PhoneNumberElement.makeExample(theme: theme)
        let checkboxButton = CheckboxElement.makeExample(theme: theme)
        let textFieldElement1 = TextFieldElement(configuration: ExampleTextFieldElementConfiguration(), theme: theme)
        let textFieldElement2 = TextFieldElement(configuration: ExampleTextFieldElementConfiguration(), theme: theme)
        let textFieldElement3 = TextFieldElement(configuration: ExampleTextFieldElementConfiguration(), theme: theme)
        let multiElementRow = SectionElement.MultiElementRow([textFieldElement1, textFieldElement2], theme: theme)

        let section1 = SectionElement(title: "Example title", elements: [multiElementRow, textFieldElement3], theme: theme)
        let section2 = SectionElement(elements: [dropdownField], theme: theme)
        let section3 = SectionElement(elements: [phoneNumberField], theme: theme)
        let section4 = SectionElement(elements: [dateField], theme: theme)
        let formElement = FormElement(
            elements: [section1, section2, section3, section4, addressSectionElement, checkboxButton],
            theme: theme
        )
        formElement.formView.backgroundColor = appearance.colors.background
        return formElement
    }
}

private extension FormElementSnapshotTest {
    func verify(
        _ formElement: FormElement,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = formElement.view
        view.autosizeHeight(width: 320)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

extension AddressSectionElement {
    static func makeExample(theme: ElementsAppearance) -> AddressSectionElement {
        let dummyAddressSpecProvider: AddressSpecProvider = {
            let specProvider = AddressSpecProvider()
            specProvider.addressSpecs = [
                "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
            ]
            return specProvider
        }()
        return AddressSectionElement(
            addressSpecProvider: dummyAddressSpecProvider,
            defaults: .init(address: .init(city: "San Francisco", country: "US", line1: "510 Townsend St.", line2: nil, postalCode: "94102", state: "California")),
            additionalFields: .init(
                billingSameAsShippingCheckbox: .enabled(isOptional: false)
            ),
            theme: theme
        )
    }
}

struct ExampleTextFieldElementConfiguration: TextFieldElementConfiguration {
    var label: String = "Label"
}

struct ExampleReadOnlyTextFieldElementConfiguration: TextFieldElementConfiguration {
    var defaultValue: String? = "Example default value"
    var label: String = "Label"
    var editConfiguration: EditConfiguration = .readOnly
}

extension CheckboxElement {
    static func makeExample(theme: ElementsAppearance) -> CheckboxElement {
        return CheckboxElement(theme: theme, label: "Lorem ipsum odor amet ", isSelectedByDefault: false)
    }
}

extension PhoneNumberElement {
    static func makeExample(theme: ElementsAppearance) -> PhoneNumberElement {
        return PhoneNumberElement(
            allowedCountryCodes: ["US"],
            defaultCountryCode: "US",
            locale: Locale(identifier: "en_US"),
            theme: theme
        )
    }
}

extension DropdownFieldElement {
    static func makeExample(theme: ElementsAppearance) -> DropdownFieldElement {
        let items = ["Example selection 1", "B", "C", "D"].map { DropdownFieldElement.DropdownItem(pickerDisplayName: $0, labelDisplayName: $0, accessibilityValue: $0, rawData: $0) }
        return DropdownFieldElement(
            items: items,
            defaultIndex: 0,
            label: "Label",
            theme: theme
        )
    }
}
