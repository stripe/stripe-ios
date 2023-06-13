//
//  IndividualElement.swift
//  StripeIdentity
//
//  Created by Chen Cen on 2/1/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class IndividualFormElement: ContainerElement {
    enum MissingType {
        case address
        case idNumber
    }

    typealias CountryNotListedButtonClicked = (MissingType) -> Void

    var elements: [StripeUICore.Element]

    var view: UIView

    var hasValidInput: Bool {
        return validationState.isValid
    }
    var collectedData: StripeAPI.VerificationPageCollectedData {
        var collectedIdNumber: StripeAPI.VerificationPageDataIdNumber?
        var collectedDob: StripeAPI.VerificationPageDataDob?
        var collectedName: StripeAPI.VerificationPageDataName?
        var collectedAddress: StripeAPI.RequiredInternationalAddress?
        var collectedPhoneNumber: StripeAPI.VerificationPageDataPhone?

        if let idNumberElement = idNumberElement {
            collectedIdNumber = idNumberElement.collectedIdNumber()
        }

        if let dobElement = dobElement {
            let dobDate = Calendar.current.dateComponents(
                [.day, .month, .year],
                from: dateFormatter.date(from: (dobElement.elements[0] as! TextFieldElement).text)!
            )

            collectedDob = StripeAPI.VerificationPageDataDob(
                day: String(dobDate.day!),
                month: String(dobDate.month!),
                year: String(dobDate.year!)
            )
        }

        if let nameElement = nameElement {
            collectedName = StripeAPI.VerificationPageDataName(
                firstName: (nameElement.elements[0] as! TextFieldElement).text,
                lastName: (nameElement.elements[1] as! TextFieldElement).text
            )
        }

        if let addressElement = addressElement {
            collectedAddress = StripeAPI.RequiredInternationalAddress(
                line1: addressElement.line1!.text,
                line2: addressElement.line2!.text.isEmpty ? nil : addressElement.line2!.text,
                city: addressElement.city?.text,
                postalCode: addressElement.postalCode?.text,
                state: addressElement.state?.rawData,
                country: addressElement.selectedCountryCode
            )
        }

        if let phoneNumberSectionElement = phoneNumberSectionElement{
            let phoneNumberElement = phoneNumberSectionElement.elements[0] as! PhoneNumberElement
            collectedPhoneNumber = StripeAPI.VerificationPageDataPhone(countryCode: phoneNumberElement.selectedCountryCode, number: phoneNumberElement.phoneNumber?.string(as: .e164))
        }

        return StripeAPI.VerificationPageCollectedData(
            idNumber: collectedIdNumber,
            dob: collectedDob,
            name: collectedName,
            address: collectedAddress,
            phone: collectedPhoneNumber
        )

    }

    let nameElement: SectionElement?
    let dobElement: SectionElement?
    let addressElement: AddressSectionElement?
    let addressCountryNotListedButtonElement: IdentityTextButtonElement?
    let idNumberElement: IdNumberElement?
    let phoneNumberSectionElement: SectionElement?
    let idCountryNotListedButtonElement: IdentityTextButtonElement?
    let countryNotListedButtonClicked: CountryNotListedButtonClicked
    let dateFormatter: DateFormatter
    weak var delegate: StripeUICore.ElementDelegate?

    init(
        individualContent: StripeAPI.VerificationPageStaticContentIndividualPage,
        missing: Set<StripeAPI.VerificationPageFieldType>,
        countryNotListedButtonClicked: @escaping CountryNotListedButtonClicked
    ) {
        self.countryNotListedButtonClicked = countryNotListedButtonClicked
        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMddyyyy"
        dateFormatter.locale = .current
        dateFormatter.timeZone = .current
        let elementsFactory = IdentityElementsFactory()

        elements = [Element]()

        if missing.contains(.phoneNumber) {
//            phoneNumberSectionElement = elementsFactory.makePhoneSection(countries: Array(individualContent.phoneNumberCountries.keys))
            phoneNumberSectionElement = elementsFactory.makePhoneSection(countries: ["US"]) // TODO(ccen) read from server
            elements.append(phoneNumberSectionElement!)
        } else {
            phoneNumberSectionElement = nil
        }
        if missing.contains(.name) {
            nameElement = elementsFactory.makeNameSection()
            elements.append(nameElement!)
        } else {
            nameElement = nil
        }
        if missing.contains(.dob) {
            dobElement = elementsFactory.makeDateOfBirthSection()
            elements.append(dobElement!)
        } else {
            dobElement = nil
        }
        if missing.contains(.idNumber) {
            idNumberElement = elementsFactory.makeIDNumberSection(
                idNumberCountries: Array(individualContent.idNumberCountries.keys)
            )
            idCountryNotListedButtonElement = IdentityTextButtonElement(
                buttonText: individualContent.idNumberCountryNotListedTextButtonText,
                didTap: {
                    countryNotListedButtonClicked(.idNumber)
                }
            )
            elements.append(idNumberElement!)
            elements.append(idCountryNotListedButtonElement!)
        } else {
            idNumberElement = nil
            idCountryNotListedButtonElement = nil
        }
        if missing.contains(.address) {
            addressElement = elementsFactory.makeAddressSection(
                countries: Array(individualContent.addressCountries.keys)
            )
            addressCountryNotListedButtonElement = IdentityTextButtonElement(
                buttonText: individualContent.addressCountryNotListedTextButtonText,
                didTap: {
                    countryNotListedButtonClicked(.address)
                }
            )
            elements.append(addressElement!)
            elements.append(addressCountryNotListedButtonElement!)
        } else {
            addressElement = nil
            addressCountryNotListedButtonElement = nil
        }
        let stack = UIStackView(
            arrangedSubviews: elements.map({ $0.view })
        )

        stack.axis = .vertical
        stack.spacing = ElementsUI.formSpacing

        view = stack

        elements.forEach { $0.delegate = self }
    }
}

// MARK: - ElementDelegate
extension IndividualFormElement: ElementDelegate {
    func didUpdate(element: Element) {
        delegate?.didUpdate(element: element)

    }

    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: element)
    }
}
