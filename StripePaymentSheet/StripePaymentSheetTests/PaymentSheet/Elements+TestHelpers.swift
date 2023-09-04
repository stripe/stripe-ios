//
//  Elements+TestHelpers.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 7/20/23.
//

@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripeUICore

extension Element {

    /// A convenience method that nwraps any Elements wrapped in `PaymentMethodElementWrapper`
    /// and returns all Elements underneath this Element, including this Element.
    public func getAllUnwrappedSubElements() -> [Element] {
        switch self {
        case let container as ContainerElement:
            return [container] + container.elements.flatMap { $0.getAllUnwrappedSubElements() }
        case let wrappedElement as PaymentMethodElementWrapper<FormElement>:
            return wrappedElement.element.getAllUnwrappedSubElements()
        case let wrappedElement as PaymentMethodElementWrapper<CheckboxElement>:
            return wrappedElement.element.getAllUnwrappedSubElements()
        case let wrappedElement as PaymentMethodElementWrapper<TextFieldElement>:
            return wrappedElement.element.getAllUnwrappedSubElements()
        case let wrappedElement as PaymentMethodElementWrapper<DropdownFieldElement>:
            return wrappedElement.element.getAllUnwrappedSubElements()
        case let wrappedElement as PaymentMethodElementWrapper<AddressSectionElement>:
            return wrappedElement.element.getAllUnwrappedSubElements()
        case let wrappedElement as PaymentMethodElementWrapper<PhoneNumberElement>:
            return [wrappedElement.element]
        case let linkEnabledPaymentElement as LinkEnabledPaymentMethodElement:
            return [linkEnabledPaymentElement] + linkEnabledPaymentElement.paymentMethodElement.getAllUnwrappedSubElements()
        case let usBankAccountFormElement as USBankAccountPaymentMethodElement:
            return [usBankAccountFormElement] + usBankAccountFormElement.formElement.getAllUnwrappedSubElements()
        default:
            return [self]
        }
    }

    func getTextFieldElement(_ label: String) -> TextFieldElement? {
        return getAllUnwrappedSubElements()
            .compactMap { $0 as? TextFieldElement }
            .first { $0.configuration.label == label }
    }

    func getDropdownFieldElement(_ label: String) -> DropdownFieldElement? {
        return getAllUnwrappedSubElements()
            .compactMap { $0 as? DropdownFieldElement }
            .first { $0.label == label }
    }

    func getMandateElement() -> SimpleMandateElement? {
        return getAllUnwrappedSubElements()
            .compactMap { $0 as? SimpleMandateElement }
            .first
    }

    func getAUBECSMandateElement() -> StaticElement? {
        return getAllUnwrappedSubElements()
            .compactMap { $0 as? StaticElement }
            .first { $0.view is AUBECSLegalTermsView }
    }

    func getPhoneNumberElement() -> PhoneNumberElement? {
        return getElement()
    }

    func getCheckboxElement(startingWith prefix: String) -> CheckboxElement? {
        return getAllUnwrappedSubElements()
            .compactMap { $0 as? CheckboxElement }
            .first { $0.label.hasPrefix(prefix) }
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
