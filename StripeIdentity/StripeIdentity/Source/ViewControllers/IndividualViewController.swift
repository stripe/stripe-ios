//
//  IndividualViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 9/23/21.
//

import UIKit
@_spi(STP) import StripeUICore

// TODO(mludowise|IDPROD-2540): These values will eventually come from a backend
// response that's been localized, but temporarily hardcoding for now.
let countryToIDNumberTypes: [String: IdentityElementsFactory.IDNumberSpec] = [
    "BR": .init(type: .BR_CPF, label: "Individual CPF"),
    "IT": .init(type: nil, label: "Fiscal code (codice fiscale)"),
    "US": .init(type: .US_SSN_LAST4, label: "Last 4 of Social Security number"),
]

final class IndividualViewController: UIViewController {

    // TODO(mludowise|IDPROD-2543): Update to match designs.
    // Currently, this serves as a placeholder to test form elements, but will
    // eventually contain different views

    let formElement: FormElement = {
        let elementsFactory = IdentityElementsFactory()

        return FormElement(elements: [
            SectionElement(elements: [
                TextFieldElement.Address.makeEmail(defaultValue: nil),
            ]),
            elementsFactory.makeIDNumberSection(countryToIDNumberTypes: countryToIDNumberTypes),
        ])
    }()

    override func viewDidLoad() {
        view.backgroundColor = CompatibleColor.systemBackground

        installViews()
        installConstraints()
    }
}

private extension IndividualViewController {
    func installViews() {
        view.addSubview(formElement.view)
    }

    func installConstraints() {
        formElement.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            formElement.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            formElement.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            formElement.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
    }
}
