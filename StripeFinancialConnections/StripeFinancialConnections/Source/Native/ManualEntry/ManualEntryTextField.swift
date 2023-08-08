//
//  ManualEntryTextField.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/23/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol ManualEntryTextFieldDelegate: AnyObject {
    func manualEntryTextField(
        _ textField: ManualEntryTextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool
    func manualEntryTextFieldDidBeginEditing(_ textField: ManualEntryTextField)
    func manualEntryTextFieldDidEndEditing(_ textField: ManualEntryTextField)
}

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
    private lazy var titleLabel: AttributedLabel = {
        let titleLabel = AttributedLabel(
            font: .label(.largeEmphasized),
            textColor: .textPrimary
        )
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return titleLabel
    }()
    private lazy var textFieldContainerView: UIView = {
        let textFieldStackView = UIStackView(
            arrangedSubviews: [
                textField
            ]
        )
        textFieldStackView.isLayoutMarginsRelativeArrangement = true
        textFieldStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        textFieldStackView.layer.cornerRadius = 8
        return textFieldStackView
    }()
    private(set) lazy var textField: UITextField = {
        let textField = IncreasedHitTestTextField()
        textField.font = FinancialConnectionsFont.label(.large).uiFont
        textField.textColor = .textPrimary
        textField.keyboardType = .numberPad
        textField.delegate = self
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
    weak var delegate: ManualEntryTextFieldDelegate?

    init(title: String, placeholder: String, footerText: String? = nil) {
        super.init(frame: .zero)
        addAndPinSubview(verticalStackView)
        titleLabel.text = title
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: FinancialConnectionsFont.label(.large).uiFont,
                .foregroundColor: UIColor.textDisabled,
            ]
        )
        self.footerText = footerText
        didUpdateFooterText()  // simulate `didSet`. it not get called in `init`
        updateBorder(highlighted: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func didUpdateFooterText() {
        currentFooterView?.removeFromSuperview()
        currentFooterView = nil

        let footerTextLabel: UIView?
        if let errorText = errorText, footerText != nil {
            footerTextLabel = ManualEntryErrorView(text: errorText)
        } else if let errorText = errorText {
            footerTextLabel = ManualEntryErrorView(text: errorText)
        } else if let footerText = footerText {
            let footerLabel = AttributedLabel(
                font: .label(.large),
                textColor: .textPrimary
            )
            footerLabel.text = footerText
            footerTextLabel = footerLabel
        } else {  // no text
            footerTextLabel = nil
        }
        if let footerTextLabel = footerTextLabel {
            verticalStackView.addArrangedSubview(footerTextLabel)
            currentFooterView = footerTextLabel
        }

        updateBorder(highlighted: textField.isFirstResponder)
    }

    private func updateBorder(highlighted: Bool) {
        let highlighted = textField.isFirstResponder

        if errorText != nil && !highlighted {
            textFieldContainerView.layer.borderColor = UIColor.borderCritical.cgColor
            textFieldContainerView.layer.borderWidth = 1.0
        } else {
            if highlighted {
                textFieldContainerView.layer.borderColor = UIColor.textBrand.cgColor
                textFieldContainerView.layer.borderWidth = 2.0
            } else {
                textFieldContainerView.layer.borderColor = UIColor.borderNeutral.cgColor
                textFieldContainerView.layer.borderWidth = 1.0
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension ManualEntryTextField: UITextFieldDelegate {

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return delegate?.manualEntryTextField(
            self,
            shouldChangeCharactersIn: range,
            replacementString: string
        ) ?? true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateBorder(highlighted: true)
        delegate?.manualEntryTextFieldDidBeginEditing(self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateBorder(highlighted: false)
        delegate?.manualEntryTextFieldDidEndEditing(self)
    }
}

private class IncreasedHitTestTextField: UITextField {
    // increase the area of TextField taps
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let largerBounds = bounds.insetBy(dx: -16, dy: -16)
        return largerBounds.contains(point)
    }
}

#if DEBUG

import SwiftUI

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

struct ManualEntryTextField_Previews: PreviewProvider {
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
