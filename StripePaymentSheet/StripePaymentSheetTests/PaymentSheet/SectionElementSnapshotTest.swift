//
//  SectionElementSnapshotTest.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/4/25.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore

// These are in StripePaymentSheet instead of StripeUICore so that we can test using PaymentSheet.Appearance rather than ElementsAppearance.
// @iOS26
final class SectionElementSnapshotTest: STPSnapshotTestCase {
    let locale_enUS = Locale(identifier: "en_US")
    let timeZone_GMT = TimeZone(secondsFromGMT: 0)!
    let dummyAddressSpecProvider: AddressSpecProvider = {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
        ]
        return specProvider
    }()
    var appearance = PaymentSheet.Appearance()
    var theme: ElementsAppearance {
        return appearance.asElementsTheme
    }

    override func setUp() {
        super.setUp()
        recordMode = true
    }

    // ☠️ WARNING: The "with_borders" snapshots are missing borders at the corners - this is a snapshot-test-only-bug and does not repro on simulator/device.
    func testDisabledState() {
        func _test(borders: Bool) {
            appearance.borderWidth = borders ? 1 : 0
            if borders {
                appearance.colors.componentBorder = .black
            }
            let textFieldElement1 = TextFieldElement(configuration: ExampleTextFieldElementConfiguration(), theme: theme)
            let textFieldElement2 = TextFieldElement(configuration: ExampleReadOnlyTextFieldElementConfiguration(), theme: theme)
            let textFieldElement3 = TextFieldElement(configuration: ExampleReadOnlyTextFieldElementConfiguration(), theme: theme)
            let textFieldElement4 = TextFieldElement(configuration: ExampleReadOnlyTextFieldElementConfiguration(), theme: theme)
            let multiElementRow = SectionElement.MultiElementRow([textFieldElement1, textFieldElement2], theme: theme)
            let multiElementSection = SectionElement(title: "Multi-element section", elements: [multiElementRow, textFieldElement3], theme: theme)
            verify(multiElementSection, identifier: "multi_element_section_" + (borders ? "with_borders" : "without_borders"))
            let singleElementSection = SectionElement(title: "Single element section", elements: [textFieldElement4], theme: theme)
            verify(singleElementSection, identifier: "single_element_section_" + (borders ? "with_borders" : "without_borders"))
        }
        _test(borders: false)
        _test(borders: true)
    }
}

private extension SectionElementSnapshotTest {
    func verify(
        _ sectionElement: SectionElement,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = sectionElement.view
        view.backgroundColor = appearance.colors.background
        view.autosizeHeight(width: 320)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}
