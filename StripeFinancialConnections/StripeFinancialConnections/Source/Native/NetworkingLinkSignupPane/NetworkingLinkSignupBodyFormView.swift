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
final class NetworkingLinkSignupBodyFormView: UIView {
    
    private(set) lazy var emailAddressTextField: UITextField = {
       let emailAddressTextField = InsetTextField()
        emailAddressTextField.placeholder = "Email address (needs to end with .com)"
        emailAddressTextField.layer.cornerRadius = 8
        emailAddressTextField.layer.borderColor = UIColor.textBrand.cgColor
        emailAddressTextField.layer.borderWidth = 2.0
        NSLayoutConstraint.activate([
            emailAddressTextField.heightAnchor.constraint(equalToConstant: 56)
        ])
        return emailAddressTextField
    }()
    
    private(set) lazy var phoneNumberTextField: UITextField = {
       let phoneNumberTextField = InsetTextField()
        phoneNumberTextField.placeholder = "Phone number"
        phoneNumberTextField.layer.cornerRadius = 8
        phoneNumberTextField.layer.borderColor = UIColor.textBrand.cgColor
        phoneNumberTextField.layer.borderWidth = 2.0
        NSLayoutConstraint.activate([
            phoneNumberTextField.heightAnchor.constraint(equalToConstant: 56)
        ])
        return phoneNumberTextField
    }()
    
    init() {
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                emailAddressTextField,
                phoneNumberTextField
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 12
        addAndPinSubview(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
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
                .frame(maxHeight: 200)
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
