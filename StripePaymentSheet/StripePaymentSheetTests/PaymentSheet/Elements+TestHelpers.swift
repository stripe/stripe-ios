//
//  Elements+TestHelpers.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 7/20/23.
//

@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripeUICore

extension Element {
    func getTextFieldElement(_ label: String) -> TextFieldElement {
        return getTextFieldElement(label)!
    }

    func getTextFieldElement(_ label: String) -> TextFieldElement? {
        return getAllUnwrappedSubElements()
            .compactMap { $0 as? TextFieldElement }
            .first { $0.configuration.label == label }
    }

    func getDropdownFieldElement(_ label: String) -> DropdownFieldElement {
        return getDropdownFieldElement(label)!
    }

    func getDropdownFieldElement(_ label: String) -> DropdownFieldElement? {
        return getAllUnwrappedSubElements()
            .compactMap { $0 as? DropdownFieldElement }
            .first { $0.label == label }
    }

    func getMandateElement() -> SimpleMandateElement? {
        return getElement()
    }

    func getAUBECSMandateElement() -> StaticElement? {
        return getAllUnwrappedSubElements()
            .compactMap { $0 as? StaticElement }
            .first { $0.view is AUBECSLegalTermsView }
    }

    func getPhoneNumberElement() -> PhoneNumberElement {
        return getPhoneNumberElement()!
    }

    func getPhoneNumberElement() -> PhoneNumberElement? {
        return getElement()
    }

    func getCheckboxElement(startingWith prefix: String) -> CheckboxElement? {
        return getAllUnwrappedSubElements()
            .compactMap { $0 as? CheckboxElement }
            .first { $0.label.hasPrefix(prefix) }
    }

    func getCardSection() -> CardSection {
        return getElement()!
    }

    func getElement<T>() -> T? {
        return getAllUnwrappedSubElements()
            .compactMap { $0 as? T }
            .first
    }
}

extension SectionElement: CustomDebugStringConvertible {
    public var debugDescription: String {
        return ["<SectionElement: \(Unmanaged.passUnretained(self).toOpaque())>", title].compactMap { $0 }.joined(separator: " - ")
    }
}

extension TextFieldElement: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "<TextFieldElement: \(Unmanaged.passUnretained(self).toOpaque())>  -  \"\(configuration.label)\"  -  \(validationState)"
    }
}

extension DropdownFieldElement {
    public override var debugDescription: String {
        return "<DropdownFieldElement: \(Unmanaged.passUnretained(self).toOpaque())>  -  \"\(label ?? "nil")\"  -  \(validationState)"
    }
}
