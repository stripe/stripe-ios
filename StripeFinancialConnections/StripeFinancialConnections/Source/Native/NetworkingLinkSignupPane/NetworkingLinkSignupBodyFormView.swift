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

@available(iOSApplicationExtension, unavailable)
protocol NetworkingLinkSignupBodyFormViewDelegate: AnyObject {
    func networkingLinkSignupBodyFormView(
        _ view: NetworkingLinkSignupBodyFormView,
        didEnterValidEmailAddress emailAddress: String
    )
    func networkingLinkSignupBodyFormViewDidEnterInvalidEmailAddress(
        _ view: NetworkingLinkSignupBodyFormView
    )
}

@available(iOSApplicationExtension, unavailable)
final class NetworkingLinkSignupBodyFormView: UIView {

    weak var delegate: NetworkingLinkSignupBodyFormViewDelegate?

    private lazy var verticalStackView: UIStackView = {
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                formElement.view
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 12
        return verticalStackView
    }()
    private lazy var theme: ElementsUITheme = {
        var theme: ElementsUITheme = .default
        theme.borderWidth = 1
        theme.cornerRadius = 8
        theme.shadow = nil
        theme.fonts = {
            var fonts = ElementsUITheme.Font()
            fonts.subheadline = .stripeFont(forTextStyle: .body)
            return fonts
        }()
        theme.colors = {
            var colors = ElementsUITheme.Color()
            colors.border = .borderNeutral
            colors.danger = .textCritical
            colors.placeholderText = .textSecondary
            colors.textFieldText = .textPrimary
            return colors
        }()
        return theme
    }()
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

    private(set) lazy var phoneNumberTextField: UITextField = {
        let phoneNumberTextField = InsetTextField()
        phoneNumberTextField.placeholder = "Phone number"
        phoneNumberTextField.layer.cornerRadius = 8
        phoneNumberTextField.layer.borderColor = UIColor.textBrand.cgColor
        phoneNumberTextField.layer.borderWidth = 2.0
        phoneNumberTextField.addTarget(
            self,
            action: #selector(phoneNumberTextFieldDidChange),
            for: .editingChanged
        )
        NSLayoutConstraint.activate([
            phoneNumberTextField.heightAnchor.constraint(equalToConstant: 56)
        ])
        return phoneNumberTextField
    }()
    private lazy var formElement = FormElement(elements: [
        emailSection,
    ], theme: theme)
    private var debounceEmailTimer: Timer?
    private var lastValidEmail: String?

    init() {
        super.init(frame: .zero)
        addAndPinSubview(verticalStackView)
        formElement.delegate = self // the `formElement` "steals" the delegate from `emailElement`
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showPhoneNumberTextFieldIfNeeded() {
        guard phoneNumberTextField.superview == nil else {
            return  // already added
        }
        verticalStackView.addArrangedSubview(phoneNumberTextField)
        // TODO(kgaidis): also add a little label together with phone numebr text field
    }

    func prefillEmailAddress(_ emailAddress: String?) {
        guard let emailAddress = emailAddress, !emailAddress.isEmpty else {
            return
        }
        emailElement.emailAddressElement.setText(emailAddress)
    }

    func beginEditingEmailAddressField() {
        emailElement.beginEditing()
    }

    @objc private func phoneNumberTextFieldDidChange() {
        print("\(phoneNumberTextField.text!)")
    }
}

@available(iOSApplicationExtension, unavailable)
extension NetworkingLinkSignupBodyFormView: ElementDelegate {
    func didUpdate(element: StripeUICore.Element) {
        switch emailElement.validationState {
        case .valid:
            if let emailAddress = emailElement.emailAddressString {
                debounceEmailTimer?.invalidate()
                debounceEmailTimer = Timer.scheduledTimer(
                    withTimeInterval: 0.3,
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
            delegate?.networkingLinkSignupBodyFormViewDidEnterInvalidEmailAddress(self)
        }
    }

    func continueToNextField(element: StripeUICore.Element) {}
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct NetworkingLinkSignupBodyFormViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingLinkSignupBodyFormView {
        NetworkingLinkSignupBodyFormView()
    }

    func updateUIView(_ uiView: NetworkingLinkSignupBodyFormView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct NetworkingLinkSignupBodyFormView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            NetworkingLinkSignupBodyFormViewUIViewRepresentable()
                .frame(maxHeight: 100)
                .padding()
            Spacer()
        }
    }
}

#endif

private class InsetTextField: UITextField {

    private let padding = UIEdgeInsets(
        top: 0,
        left: 10,
        bottom: 0,
        right: 10
    )

    override open func textRect(
        forBounds bounds: CGRect
    ) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(
        forBounds bounds: CGRect
    ) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(
        forBounds bounds: CGRect
    ) -> CGRect {
        return bounds.inset(by: padding)
    }
}
