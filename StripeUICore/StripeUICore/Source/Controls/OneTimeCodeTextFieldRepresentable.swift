//
//  OneTimeCodeTextFieldRepresentable.swift
//  StripeUICore
//
//  Created by Mat Schmid on 6/4/25.
//

import SwiftUI

@_spi(STP) public struct OneTimeCodeTextFieldRepresentable: UIViewRepresentable {
    @Binding var text: String
    var configuration: OneTimeCodeTextField.Configuration
    var theme: ElementsAppearance
    var isEnabled: Bool = true
    var onComplete: ((String) -> Void)?

    @_spi(STP) public init(
        text: Binding<String>,
        configuration: OneTimeCodeTextField.Configuration = OneTimeCodeTextField.Configuration(),
        theme: ElementsAppearance = .default,
        isEnabled: Bool = true,
        onComplete: ((String) -> Void)? = nil
    ) {
        self._text = text
        self.configuration = configuration
        self.theme = theme
        self.isEnabled = isEnabled
        self.onComplete = onComplete
    }

    @_spi(STP) public func makeUIView(context: Context) -> OneTimeCodeTextField {
        let textField = OneTimeCodeTextField(configuration: configuration, theme: theme)
        textField.isEnabled = isEnabled
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textFieldDidChange(_:)),
            for: .valueChanged
        )
        return textField
    }

    @_spi(STP) public func updateUIView(_ uiView: OneTimeCodeTextField, context: Context) {
        if uiView.value != text {
            uiView.value = text
        }
        uiView.isEnabled = isEnabled
    }

    @_spi(STP) public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    @_spi(STP) public class Coordinator: NSObject {
        var parent: OneTimeCodeTextFieldRepresentable

        init(parent: OneTimeCodeTextFieldRepresentable) {
            self.parent = parent
        }

        @objc func textFieldDidChange(_ textField: OneTimeCodeTextField) {
            parent.text = textField.value

            if textField.isComplete {
                parent.onComplete?(textField.value)
            }
        }
    }
}
