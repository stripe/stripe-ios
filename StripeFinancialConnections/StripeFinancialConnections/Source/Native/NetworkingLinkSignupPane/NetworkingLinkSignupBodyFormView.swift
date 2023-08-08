//
//  NetworkingLinkSignupBodyFormView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/24/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol NetworkingLinkSignupBodyFormViewDelegate: AnyObject {
    func networkingLinkSignupBodyFormView(
        _ view: NetworkingLinkSignupBodyFormView,
        didEnterValidEmailAddress emailAddress: String
    )
    func networkingLinkSignupBodyFormViewDidUpdateFields(
        _ view: NetworkingLinkSignupBodyFormView
    )
}

final class NetworkingLinkSignupBodyFormView: UIView {

    private let accountholderPhoneNumber: String?
    weak var delegate: NetworkingLinkSignupBodyFormViewDelegate?

    private lazy var formElement = FormElement(
        elements: [
            emailSection,
            phoneNumberSection,
        ],
        theme: theme
    )
    private lazy var emailSection = SectionElement(elements: [emailElement], theme: theme)
    private (set) lazy var emailElement: LinkEmailElement = {
        let emailElement = LinkEmailElement(theme: theme)
        emailElement.indicatorTintColor = .textPrimary
        emailElement.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emailElement.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
        return emailElement
    }()
    private lazy var phoneNumberSection = SectionElement(
        elements: [phoneNumberElement],
        theme: theme
    )
    private(set) lazy var phoneNumberElement: PhoneNumberElement = {
        let phoneNumberElement = PhoneNumberElement(
            // TODO(kgaidis): Stripe.js selects country via Stripe.js library
            defaultCountryCode: nil, // the component automatically selects this based off locale
            defaultPhoneNumber: accountholderPhoneNumber,
            theme: theme
        )
        phoneNumberElement.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            phoneNumberElement.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
        return phoneNumberElement
    }()
    private lazy var theme: ElementsUITheme = {
        var theme: ElementsUITheme = .default
        theme.borderWidth = 1
        theme.cornerRadius = 8
        theme.shadow = nil
        theme.fonts = {
            var fonts = ElementsUITheme.Font()
            fonts.subheadline = FinancialConnectionsFont.label(.large).uiFont
            return fonts
        }()
        theme.colors = {
            var colors = ElementsUITheme.Color()
            colors.border = .borderNeutral
            colors.danger = .textCritical
            colors.placeholderText = .textSecondary
            colors.textFieldText = .textPrimary
            colors.parentBackground = .customBackgroundColor
            colors.background = .customBackgroundColor
            return colors
        }()
        return theme
    }()
    private var debounceEmailTimer: Timer?
    private var lastValidEmail: String?

    init(accountholderPhoneNumber: String?) {
        self.accountholderPhoneNumber = accountholderPhoneNumber
        super.init(frame: .zero)
        addAndPinSubview(formElement.view)
        formElement.delegate = self
        phoneNumberSection.view.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // returns `true` if the phone number field was shown for the first time
    func showPhoneNumberFieldIfNeeded() -> Bool {
        let isPhoneNumberFieldHidden = phoneNumberSection.view.isHidden
        guard isPhoneNumberFieldHidden else {
            return false // phone number field is already shown
        }
        formElement.setElements(
            [emailSection, phoneNumberSection],
            hidden: false,
            animated: true
        )
        return true // phone number is shown for the first time
    }

    func prefillEmailAddress(_ emailAddress: String?) {
        guard let emailAddress = emailAddress, !emailAddress.isEmpty else {
            return
        }
        emailElement.emailAddressElement.setText(emailAddress)
    }

    func endEditingEmailAddressField() {
        emailElement.view.endEditing(true)
    }

    func beginEditingPhoneNumberField() {
        _ = phoneNumberElement.beginEditing()
    }
}

extension NetworkingLinkSignupBodyFormView: ElementDelegate {
    func didUpdate(element: StripeUICore.Element) {
        delegate?.networkingLinkSignupBodyFormViewDidUpdateFields(self)

        switch emailElement.validationState {
        case .valid:
            if let emailAddress = emailElement.emailAddressString {
                debounceEmailTimer?.invalidate()
                debounceEmailTimer = Timer.scheduledTimer(
                    // TODO(kgaidis): discuss this logic w/ team; Stripe.js is constant 0.3
                    //
                    // a valid e-mail will transition the user to the phone number
                    // field (sometimes prematurely), so we increase debounce if
                    // if there's a high chance the e-mail is not yet finished
                    // being typed (high chance of not finishing == not .com suffix)
                    withTimeInterval: emailAddress.hasSuffix(".com") ? 0.3 : 1.0,
                    repeats: false
                ) { [weak self] _ in
                    guard let self = self else { return }
                    if
                        self.emailElement.validationState.isValid,
                        // `lastValidEmail` ensures that we only
                        // fire the delegate ONCE per unique valid email
                        emailAddress != self.lastValidEmail
                    {
                        self.lastValidEmail = emailAddress
                        self.delegate?.networkingLinkSignupBodyFormView(
                            self,
                            didEnterValidEmailAddress: emailAddress
                        )
                    }
                }
            }
        case .invalid:
            // errors are displayed automatically by the component
            lastValidEmail = nil
        }
    }

    func continueToNextField(element: StripeUICore.Element) {}
}

#if DEBUG

import SwiftUI

private struct NetworkingLinkSignupBodyFormViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingLinkSignupBodyFormView {
        NetworkingLinkSignupBodyFormView(accountholderPhoneNumber: nil)
    }

    func updateUIView(_ uiView: NetworkingLinkSignupBodyFormView, context: Context) {}
}

struct NetworkingLinkSignupBodyFormView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            NetworkingLinkSignupBodyFormViewUIViewRepresentable()
                .frame(maxHeight: 200)
                .padding()
            Spacer()
        }
    }
}

#endif
