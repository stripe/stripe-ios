//
//  ManualEntryTextField.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/23/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class ManualEntryTextField: UIView {
    
    private lazy var verticalStackView: UIStackView = {
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                titleLabel,
                textFieldContainerView,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 6
        return verticalStackView
    }()
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .stripeFont(forTextStyle: .bodyEmphasized)
        titleLabel.textColor = .textPrimary
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return titleLabel
    }()
    private lazy var textFieldContainerView: UIView = {
        let textFieldStackView = UIStackView(
            arrangedSubviews: [
                textField,
            ]
        )
        textFieldStackView.isLayoutMarginsRelativeArrangement = true
        textFieldStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 12,
            bottom: 8,
            trailing: 12
        )
        textFieldStackView.layer.cornerRadius = 4
        return textFieldStackView
    }()
    private(set) lazy var textField: UITextField = {
        let textField = UITextField()
        textField.font = .stripeFont(forTextStyle: .bodyEmphasized)
        textField.textColor = .textPrimary
        return textField
    }()
    private var currentFooterView: UIView?
    
    var text: String {
        get {
            return textField.text ?? ""
        }
        set {
            textField.text = newValue
        }
    }
    private var footerText: String? {
        didSet {
            didUpdateFooterText()
        }
    }
    var errorText: String? {
        didSet {
            didUpdateFooterText()
        }
    }
    
    init(title: String, placeholder: String, footerText: String? = nil) {
        super.init(frame: .zero)
        addAndPinSubview(verticalStackView)
        titleLabel.text = title
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: UIFont.stripeFont(forTextStyle: .body),
                .foregroundColor: UIColor.textDisabled,
            ]
        )
        self.footerText = footerText
        didUpdateFooterText() // simulate `didSet`. it not get called in `init`
        updateBorder()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func didUpdateFooterText() {
        currentFooterView?.removeFromSuperview()
        currentFooterView = nil
        
        let footerTextLabel: UIView?
        if let errorText = errorText, let _ = footerText {
            footerTextLabel = CreateErrorLabel(text: errorText)
        } else if let errorText = errorText {
            footerTextLabel = CreateErrorLabel(text: errorText)
        } else if let footerText = footerText {
            let footerLabel = UILabel()
            footerLabel.font = .stripeFont(forTextStyle: .body)
            footerLabel.textColor = .textPrimary
            footerLabel.text = footerText
            footerTextLabel = footerLabel
        } else { // no text
            footerTextLabel = nil
        }
        if let footerTextLabel = footerTextLabel {
            verticalStackView.addArrangedSubview(footerTextLabel)
            currentFooterView = footerTextLabel
        }
        
        updateBorder()
    }
    
    private func updateBorder() {
        if errorText != nil {
            textFieldContainerView.layer.borderColor = UIColor.borderCritical.cgColor
            textFieldContainerView.layer.borderWidth = 2.0 / UIScreen.main.nativeScale
        } else {
            textFieldContainerView.layer.borderColor = UIColor.borderNeutral.cgColor
            textFieldContainerView.layer.borderWidth = 2.0 / UIScreen.main.nativeScale
        }
    }
}

private func CreateErrorLabel(text: String) -> UIView {
    let warningIconImageView = UIImageView()
    if #available(iOSApplicationExtension 13.0, *) {
        warningIconImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")?
            .withTintColor(.textCritical, renderingMode: .alwaysOriginal)
    } else {
        assertionFailure()
    }
    warningIconImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        warningIconImageView.widthAnchor.constraint(equalToConstant: 14),
        warningIconImageView.heightAnchor.constraint(equalToConstant: 14),
    ])
    
    let errorLabel = UILabel()
    errorLabel.font = .stripeFont(forTextStyle: .body)
    errorLabel.textColor = .textCritical
    errorLabel.text = text
    errorLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            warningIconImageView,
            errorLabel,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 5
    horizontalStackView.alignment = .center
    return horizontalStackView
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
private struct ManualEntryTextFieldUIViewRepresentable: UIViewRepresentable {
    
    let title: String
    let placeholder: String
    let footerText: String?
    let errorText: String?
    
    func makeUIView(context: Context) -> ManualEntryTextField {
        ManualEntryTextField(
            title: title,
            placeholder: placeholder,
            footerText: footerText
        )
    }
    
    func updateUIView(_ uiView: ManualEntryTextField, context: Context) {
        uiView.errorText = errorText
    }
}

@available(iOSApplicationExtension, unavailable)
struct ManualEntryTextField_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack(spacing: 16) {
                ManualEntryTextFieldUIViewRepresentable(
                    title: "Routing number",
                    placeholder: "123456789",
                    footerText: nil,
                    errorText: nil
                )
                ManualEntryTextFieldUIViewRepresentable(
                    title: "Account number",
                    placeholder: "000123456789",
                    footerText: "Your account can be checkings or savings.",
                    errorText: nil
                )
                ManualEntryTextFieldUIViewRepresentable(
                    title: "Confirm account number",
                    placeholder: "000123456789",
                    footerText: nil,
                    errorText: nil
                )
                ManualEntryTextFieldUIViewRepresentable(
                    title: "Routing number",
                    placeholder: "123456789",
                    footerText: nil,
                    errorText: "Routing number is required."
                )
                ManualEntryTextFieldUIViewRepresentable(
                    title: "Account number",
                    placeholder: "000123456789",
                    footerText: "Your account can be checkings or savings.",
                    errorText: "Account number is required."
                )
                Spacer()
            }
            .frame(maxHeight: 500)
            .padding()
            .background(Color(UIColor.customBackgroundColor))
        }
    }
}

#endif
