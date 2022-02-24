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
let addressCountryAllowList: [String] = ["US", "IN", "CA", "UK", "JP", "BR"]

final class IndividualViewController: IdentityFlowViewController {

    // TODO(mludowise|IDPROD-2543): Update to match designs.
    // Currently, this serves as a placeholder to test form elements, but will
    // eventually contain different views

    let formElement: FormElement = {
        let elementsFactory = IdentityElementsFactory()

        return FormElement(elements: [
            elementsFactory.makeNameSection(),
            SectionElement(elements: [
                TextFieldElement.Address.makeEmail(defaultValue: nil),
            ]),
            SectionElement(elements: [
                elementsFactory.makeDateOfBirth(),
            ]),
            elementsFactory.makeIDNumberSection(countryToIDNumberTypes: countryToIDNumberTypes),
            elementsFactory.makeAddressSection(countries: addressCountryAllowList)
        ])
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO(mludowise|IDPROD-2543): Text will eventually come from backend
        // response that's been localized and button tap will do something other
        // than dismiss.
        // TODO(jaimepark): Update view to match design. Add nil header view just to ease compiler
        configure(
            backButtonTitle: "Info",
            viewModel: .init(
                headerViewModel: nil,
                contentView: formElement.view,
                buttonText: "Submit",
                didTapButton: { [weak self] in
                    self?.dismiss(animated: true, completion: nil)
                }
            )
        )
    }
}
