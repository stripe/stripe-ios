//
//  CountryNotListedLabelElement.swift
//  StripeIdentity
//
//  Created by Chen Cen on 2/2/23.
//

import Foundation

@_spi(STP) import StripeUICore
import UIKit

final class IdentityTextButtonElement: Element {
    let collectsUserInput: Bool = true

    typealias DidTapIdentityTextButton = () -> Void
    weak var delegate: StripeUICore.ElementDelegate?

    lazy var view: UIView = {
        let container = UIStackView(
            arrangedSubviews: [countryNotListedButton]
        )
        container.axis = .vertical
        container.alignment = .leading

        return container
    }()

    let buttonText: String
    let didTap: DidTapIdentityTextButton

    lazy var countryNotListedButton: Button = {
        let countryNotListedButton = Button(configuration: .identityTextButtonConfiguration, title: buttonText)
        countryNotListedButton.addTarget(self, action: #selector(didTapButton(button:)), for: .touchUpInside)
        return countryNotListedButton
    }()

    init(buttonText: String, didTap: @escaping DidTapIdentityTextButton) {
        self.buttonText = buttonText
        self.didTap = didTap
    }

    @objc fileprivate func didTapButton(button: Button) {
        didTap()
    }
}

fileprivate extension Button.Configuration {
    static var identityTextButtonConfiguration: Button.Configuration {
        var identityCountryNotListed = Button.Configuration.plain()
        identityCountryNotListed.font = IdentityUI.preferredFont(forTextStyle: .body, weight: .regular).withSize(13)
        return identityCountryNotListed
    }
}
