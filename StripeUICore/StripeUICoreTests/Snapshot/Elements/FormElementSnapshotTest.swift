//
//  FormElementSnapshotTest.swift
//  StripeUICoreTests
//
//  Created by Yuki Tokuhiro on 9/4/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripeUICore

final class FormElementSnapshotTest: STPSnapshotTestCase {
    let locale_enUS = Locale(identifier: "en_US")
    let timeZone_GMT = TimeZone(secondsFromGMT: 0)!
    let dummyAddressSpecProvider: AddressSpecProvider = {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
        ]
        return specProvider
    }()
    var theme: ElementsAppearance = .default

    struct MockTextFieldElementConfiguration: TextFieldElementConfiguration {
        var defaultValue: String?
        var label: String = "label"
        func maxLength(for text: String) -> Int { "default value".count }
    }

    override func setUp() {
        super.setUp()
        recordMode = true
    }

    func testDefaultTheme() {
        // Make every element we know about
        let addressSectionElement = AddressSectionElement(
            addressSpecProvider: dummyAddressSpecProvider,
            defaults: .init(address: .init(city: "San Francisco", country: "US", line1: "510 Townsend St.", line2: nil, postalCode: "94102", state: "California")),
            additionalFields: .init(
                billingSameAsShippingCheckbox: .enabled(isOptional: false)
            )
        )
        let dateField = DateFieldElement(
            label: "Label",
            defaultDate: nil,
            maximumDate: nil,
            locale: locale_enUS,
            timeZone: timeZone_GMT
        )
        let dropdownField = makeDropdownFieldElement()
        let checkboxButton = CheckboxElement(theme: theme, label: "Save my info for secure 1-click checkout", isSelectedByDefault: false)
        let phoneNumberField = PhoneNumberElement(
            allowedCountryCodes: ["US"],
            defaultCountryCode: "US",
            locale: Locale(identifier: "en_US")
        )
        let textFieldElement1 = TextFieldElement(configuration: MockTextFieldElementConfiguration())
        let textFieldElement2 = TextFieldElement(configuration: MockTextFieldElementConfiguration())
        let textFieldElement3 = TextFieldElement(configuration: MockTextFieldElementConfiguration())
        let multiElementRow = SectionElement.MultiElementRow([textFieldElement1, textFieldElement2], theme: theme)

        let section1 = SectionElement(title: "Example title", elements: [multiElementRow, textFieldElement3], theme: theme)
        let section2 = SectionElement(elements: [dropdownField], theme: theme)
        let section3 = SectionElement(elements: [phoneNumberField], theme: theme)
        let section4 = SectionElement(elements: [dateField], theme: theme)
        let formElement = FormElement(
            elements: [section1, section2, section3, section4, addressSectionElement, checkboxButton],
            theme: theme
        )
        verify(formElement)
    }

    func makeDropdownFieldElement() -> DropdownFieldElement {
        let items = ["A", "B", "C", "D"].map { DropdownFieldElement.DropdownItem(pickerDisplayName: $0, labelDisplayName: $0, accessibilityValue: $0, rawData: $0) }
        return DropdownFieldElement(
            items: items,
            defaultIndex: 0,
            label: "Label",
            theme: theme
        )
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
