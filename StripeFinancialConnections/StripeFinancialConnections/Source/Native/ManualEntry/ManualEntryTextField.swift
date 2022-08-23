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
        textField.font = .stripeFont(forTextStyle: .body)
        textField.textColor = .textPrimary
        return textField
    }()
    
    private lazy var footerContainerView: UIView = {
       let footerContainerView = UIView()
        return footerContainerView
    }()
    
    var footerText: String? {
        didSet {
            didUpdateFooterText()
        }
    }
    
    var footerErrorText: String? {
        didSet {
            didUpdateFooterText()
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        let titleLabel = UILabel()
        titleLabel.font = .stripeFont(forTextStyle: .bodyEmphasized)
        titleLabel.textColor = .textPrimary
        titleLabel.text = "Routing number"
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)

        setPlaceholder("123456789")
        footerText = "Your account can be checkings or savings."
        footerErrorText = "Routing number is required"
        didUpdateFooterText()
        
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                titleLabel,
                textFieldContainerView,
                footerContainerView,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 5
        addAndPinSubview(verticalStackView)
        
        updateBorder()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setPlaceholder(_ placeholderText: String) {
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.textDisabled
            ]
        )
    }
    
    private func didUpdateFooterText() {
        footerContainerView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        let footerTextLabel: UIView?
        
        if let footerErrorText = footerErrorText, let _ = footerText {
            footerTextLabel = CreateErrorLabel(text: footerErrorText)
        } else if let footerErrorText = footerErrorText {
            footerTextLabel = CreateErrorLabel(text: footerErrorText)
        } else if let footerText = footerText {
            print(footerText)
            let footerLabel = UILabel()
            footerLabel.font = .stripeFont(forTextStyle: .body)
            footerLabel.textColor = .textPrimary
            footerLabel.text = footerText
            footerTextLabel = footerLabel
        } else { // no text
            footerTextLabel = nil
        }
        
        if let footerTextLabel = footerTextLabel {
            footerContainerView.addAndPinSubview(footerTextLabel)
        }
        
        updateBorder()
    }
    
    private func updateBorder() {
        if footerErrorText != nil {
            textFieldContainerView.layer.borderColor = UIColor.red.cgColor
            textFieldContainerView.layer.borderWidth = 2.0 / UIScreen.main.nativeScale
        } else {
            textFieldContainerView.layer.borderColor = UIColor.borderCritical.cgColor
            textFieldContainerView.layer.borderWidth = 2.0 / UIScreen.main.nativeScale
        }
    }
}

private func CreateErrorLabel(text: String) -> UIView {
    let warningIcon = UIView()
    warningIcon.backgroundColor = .borderCritical
    warningIcon.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        warningIcon.widthAnchor.constraint(equalToConstant: 12),
        warningIcon.heightAnchor.constraint(equalToConstant: 12),
    ])
    
    let errorLabel = UILabel()
    errorLabel.font = .stripeFont(forTextStyle: .body)
    errorLabel.textColor = .textCritical
    errorLabel.text = text
    
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            warningIcon,
            errorLabel,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 5
    return horizontalStackView
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
private struct ManualEntryTextFieldUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ManualEntryTextField {
        ManualEntryTextField()
    }
    
    func updateUIView(_ uiView: ManualEntryTextField, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct ManualEntryTextField_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack {
                ManualEntryTextFieldUIViewRepresentable()
                Spacer()
            }
            .frame(maxHeight: 200)
            .padding()
            .background(Color(UIColor.customBackgroundColor))
        }
    }
}

#endif
