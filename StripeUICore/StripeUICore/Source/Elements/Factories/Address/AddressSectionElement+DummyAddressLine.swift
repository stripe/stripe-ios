//
//  AddressSectionElement+DummyAddressLine.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 7/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

extension AddressSectionElement {
    /// Looks like a "Address" text field but with the text field disabled
    @_spi(STP) public class DummyAddressLine: NSObject, Element, TextFieldViewDelegate, UIGestureRecognizerDelegate {
        public var delegate: ElementDelegate?
        public lazy var view: UIView = {
            let configuration = TextFieldElement.Address.LineConfiguration(lineType: .autoComplete, defaultValue: nil)
            let text = ""
            let viewModel = TextFieldElement.ViewModel(
                placeholder: configuration.label,
                accessibilityLabel: configuration.accessibilityLabel,
                attributedText: configuration.makeDisplayText(for: text),
                keyboardProperties: configuration.keyboardProperties(for: text),
                validationState: configuration.validate(text: text, isOptional: configuration.isOptional),
                accessoryView: configuration.accessoryView(for: text, theme: theme),
                shouldShowClearButton: configuration.shouldShowClearButton,
                theme: theme
            )
            let textFieldView = TextFieldView(viewModel: viewModel, delegate: self)
            textFieldView.isUserInteractionEnabled = false
            let view = UIView()
            view.addAndPinSubview(textFieldView)
            view.addGestureRecognizer(autocompleteLineTapRecognizer)
            return view
        }()
        public var validationState: ElementValidationState {
            return .invalid(error: TextFieldElement.Error.empty, shouldDisplay: false)
        }
        public var didTap: () -> () = {}
        public let theme: ElementsUITheme
        private lazy var autocompleteLineTapRecognizer: UITapGestureRecognizer = {
            let tap = UITapGestureRecognizer(target: self, action: #selector(_didTap))
            tap.delegate = self
            return tap
        }()
        
        @objc func _didTap() {
            didTap()
        }
        
        func textFieldViewDidUpdate(view: TextFieldView) {
            // no-op
        }
        
        func textFieldViewContinueToNextField(view: TextFieldView) {
            // no-op
        }
        
        public func beginEditing() -> Bool {
            // no-op but pretend we did begin editing
            return true
        }
        
        public init(theme: ElementsUITheme) {
            self.theme = theme
            super.init()
        }
    }
}
