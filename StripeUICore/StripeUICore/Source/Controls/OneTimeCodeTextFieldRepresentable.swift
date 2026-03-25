//
//  OneTimeCodeTextFieldRepresentable.swift
//  StripeUICore
//
//  Created by Mat Schmid on 6/4/25.
//

import SwiftUI

// Controller to hold a reference to the underlying `OneTimeCodeTextField`
@_spi(STP) public final class OneTimeCodeTextFieldController {
    private weak var textField: OneTimeCodeTextField?

    @_spi(STP) public init() {}

    fileprivate func setTextField(_ textField: OneTimeCodeTextField) {
        self.textField = textField
    }

    @_spi(STP) public func performInvalidCodeAnimation() {
        textField?.performInvalidCodeAnimation()
    }
}

@_spi(STP) public struct OneTimeCodeTextFieldRepresentable: UIViewRepresentable {
    @Binding private var text: String
    private var configuration: OneTimeCodeTextField.Configuration
    private var controller: OneTimeCodeTextFieldController?
    private var theme: ElementsAppearance
    private var isEnabled: Bool = true
    private var onComplete: ((String) -> Void)?

    @_spi(STP) public init(
        text: Binding<String>,
        configuration: OneTimeCodeTextField.Configuration = OneTimeCodeTextField.Configuration(),
        controller: OneTimeCodeTextFieldController?,
        theme: ElementsAppearance = .default,
        isEnabled: Bool = true,
        onComplete: ((String) -> Void)? = nil
    ) {
        self._text = text
        self.configuration = configuration
        self.controller = controller
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
        controller?.setTextField(textField)
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
