//
//  PhoneCountryCodeSelectorView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/30/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol PhoneCountryCodeSelectorViewDelegate: AnyObject {

}

final class PhoneCountryCodeSelectorView: UIView {

    private lazy var flagLabel: AttributedLabel = {
        let flagLabel = AttributedLabel(
            font: .label(.large),
            textColor: .textDefault
        )
        flagLabel.setText("🇺🇸")
        return flagLabel
    }()
    private lazy var countryCodeLabel: AttributedLabel = {
        let flagLabel = AttributedLabel(
            font: .label(.large),
            textColor: .textDefault
        )
        flagLabel.setText("+1")
        return flagLabel
    }()
    private lazy var textField: UITextField = {
        let textField = UnselectableTextField()
        textField.autocorrectionType = .no
        textField.tintColor = .clear
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.inputView = pickerView
        textField.inputAccessoryView = keyboardToolbar
        return textField
    }()
    private lazy var keyboardToolbar: DoneButtonToolbar = {
        var theme: ElementsUITheme = .default
        theme.colors = {
            var colors = ElementsUITheme.Color()
            colors.primary = .brand500
            colors.secondaryText = .textSubdued
            return colors
        }()
        let keyboardToolbar = DoneButtonToolbar(
            delegate: self,
            showCancelButton: true,
            theme: theme
        )
        return keyboardToolbar
    }()
    private lazy var pickerView: PhoneCountryCodePickerView = {
        let pickerView = PhoneCountryCodePickerView()
        return pickerView
    }()

    weak var delegate: PhoneCountryCodeSelectorViewDelegate?

    init() {
        super.init(frame: .zero)

        backgroundColor = .backgroundOffset
        layer.cornerRadius = 8
        clipsToBounds = true

        let horizontalStackView = UIStackView(
            arrangedSubviews: [
                flagLabel,
                countryCodeLabel,
            ]
        )
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 8
        horizontalStackView.isLayoutMarginsRelativeArrangement = true
        horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 12,
            leading: 12,
            bottom: 12,
            trailing: 12
        )
        addAndPinSubview(horizontalStackView)

        addAndPinSubview(textField)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func endEditing(_ force: Bool) -> Bool {
        _ = textField.endEditing(force)
        return super.endEditing(force)
    }
}

// MARK: - DoneButtonToolbarDelegate

extension PhoneCountryCodeSelectorView: DoneButtonToolbarDelegate {
    func didTapDone(_ toolbar: DoneButtonToolbar) {
        textField.endEditing(true)
    }

    func didTapCancel(_ toolbar: DoneButtonToolbar) {
        textField.endEditing(true)
    }
}

private class UnselectableTextField: UITextField {
    override func caretRect(for position: UITextPosition) -> CGRect {
        // Disallow selection
        return .zero
    }

    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        // Disallow selection
        return []
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}

#if DEBUG

import SwiftUI

private struct PhoneCountryCodeSelectorViewUIViewRepresentable: UIViewRepresentable {

    let text: String

    func makeUIView(context: Context) -> PhoneCountryCodeSelectorView {
        PhoneCountryCodeSelectorView()
    }

    func updateUIView(
        _ PhoneCountryCodeSelectorView: PhoneCountryCodeSelectorView,
        context: Context
    ) {

    }
}

struct PhoneCountryCodeSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack(spacing: 16) {
                PhoneCountryCodeSelectorViewUIViewRepresentable(
                    text: ""
                )
                .frame(width: 72, height: 48)

                PhoneCountryCodeSelectorViewUIViewRepresentable(
                    text: "4015006000"
                )
                .frame(width: 72, height: 48)

                PhoneCountryCodeSelectorViewUIViewRepresentable(
                    text: "401500600"
                )
                .frame(width: 72, height: 48)

                PhoneCountryCodeSelectorViewUIViewRepresentable(
                    text: "40150060003435"
                )
                .frame(width: 72, height: 48)

                Spacer()
            }
            .padding()
            .background(Color(UIColor.customBackgroundColor))
        }
    }
}

#endif
