//
//  STPFormTextField.swift
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

import UIKit

enum STPFormTextFieldAutoFormattingBehavior: Int {
    case none
    case phoneNumbers
    case cardNumbers
    case expiration
    case bsbNumber
}

@objc protocol STPFormTextFieldDelegate: UITextFieldDelegate {
    // Note, post-Swift conversion:
    // In lieu of a real delegate proxy, this should always be implemented and call:
    //    if let textField = textField as? STPFormTextField, let delegateProxy = textField.delegateProxy {
    //        return delegateProxy.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
    //    }
    //    return true
    @objc(textField:shouldChangeCharactersInRange:replacementString:) func textField(
        _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool

    @objc optional func formTextFieldDidBackspace(onEmpty formTextField: STPFormTextField)
    @objc optional func formTextField(
        _ formTextField: STPFormTextField,
        modifyIncomingTextChange input: NSAttributedString
    ) -> NSAttributedString
    @objc optional func formTextFieldTextDidChange(_ textField: STPFormTextField)
}

@objc class STPFormTextField: STPValidatedTextField {

    private var _selectionEnabled = false
    var selectionEnabled: Bool {
        get {
            _selectionEnabled
        }
        set(selectionEnabled) {
            _selectionEnabled = selectionEnabled
            delegateProxy?.selectionEnabled = selectionEnabled
        }
    }
    /* defaults to NO */
    var preservesContentsOnPaste = false
    // defaults to NO
    private var _compressed = false
    var compressed: Bool {
        get {
            _compressed
        }
        set(compressed) {
            if compressed != _compressed {
                _compressed = compressed
                // reset text values as needed
                _didSetText(text: self.text ?? "")
                _didSetAttributedPlaceholder(attributedPlaceholder: attributedPlaceholder)
            }
        }
    }
    // defaults to NO
    private var _autoFormattingBehavior: STPFormTextFieldAutoFormattingBehavior = .none
    var autoFormattingBehavior: STPFormTextFieldAutoFormattingBehavior {
        get {
            _autoFormattingBehavior
        }
        set(autoFormattingBehavior) {
            _autoFormattingBehavior = autoFormattingBehavior
            delegateProxy?.autoformattingBehavior = autoFormattingBehavior
            switch autoFormattingBehavior {
            case .none, .expiration:
                textFormattingBlock = nil
            case .cardNumbers:
                textFormattingBlock = { inputString in
                    guard let inputString = inputString else {
                        return NSAttributedString()
                    }
                    if !STPCardValidator.stringIsNumeric(inputString.string) {
                        return inputString
                    }
                    let attributedString = NSMutableAttributedString(attributedString: inputString)
                    let cardNumberFormat = STPCardValidator.cardNumberFormat(
                        forCardNumber: attributedString.string)
                    var index = 0
                    for segmentLength in cardNumberFormat {
                        var segmentIndex = 0

                        while index < (attributedString.length)
                            && segmentIndex < Int(segmentLength.uintValue)
                        {
                            if index + 1 != attributedString.length
                                && segmentIndex + 1 == Int(segmentLength.uintValue)
                            {
                                attributedString.addAttribute(
                                    .kern,
                                    value: NSNumber(value: 5),
                                    range: NSRange(location: index, length: 1))
                            } else {
                                attributedString.addAttribute(
                                    .kern,
                                    value: NSNumber(value: 0),
                                    range: NSRange(location: index, length: 1))
                            }

                            index += 1
                            segmentIndex += 1
                        }
                    }
                    return attributedString
                }
            case .phoneNumbers:
                weak var weakSelf = self
                textFormattingBlock = { inputString in
                    if !STPCardValidator.stringIsNumeric(inputString?.string ?? "") {
                        return inputString!
                    }
                    guard let strongSelf = weakSelf else {
                        return inputString!
                    }
                    let phoneNumber = STPPhoneNumberValidator.formattedSanitizedPhoneNumber(
                        for: inputString?.string ?? "")
                    let attributes = type(of: strongSelf).attributes(for: inputString)
                    return NSAttributedString(
                        string: phoneNumber,
                        attributes: attributes as? [NSAttributedString.Key: Any])
                }
            case .bsbNumber:
                weak var weakSelf = self
                textFormattingBlock = { inputString in
                    guard let inputString = inputString else {
                        return NSAttributedString()
                    }
                    if !STPBSBNumberValidator.isStringNumeric(inputString.string) {
                        return inputString
                    }
                    guard let strongSelf = weakSelf else {
                        return NSAttributedString()
                    }
                    let bsbNumber = STPBSBNumberValidator.formattedSanitizedText(
                        from: inputString.string)
                    let attributes = type(of: strongSelf).attributes(for: inputString)
                    return NSAttributedString(
                        string: bsbNumber ?? "",
                        attributes: attributes as? [NSAttributedString.Key: Any])
                }
            }
        }
    }

    private weak var _formDelegate: STPFormTextFieldDelegate?
    weak var formDelegate: STPFormTextFieldDelegate? {
        get {
            _formDelegate
        }
        set(formDelegate) {
            _formDelegate = formDelegate
            delegate = formDelegate
        }
    }
    var delegateProxy: STPTextFieldDelegateProxy?
    private var textFormattingBlock: STPFormTextTransformationBlock?

    class func attributes(for attributedString: NSAttributedString?) -> [AnyHashable: Any]? {
        if attributedString?.length == 0 {
            return [:]
        }
        return attributedString?.attributes(
            at: 0, longestEffectiveRange: nil,
            in: NSRange(location: 0, length: attributedString?.length ?? 0))
    }

    /// :nodoc:
    @objc
    public override func insertText(_ text: String) {
        self.text = self.text ?? "" + text
    }

    /// :nodoc:
    @objc
    public override func deleteBackward() {
        super.deleteBackward()
        if (text?.count ?? 0) == 0 {
            if formDelegate?.responds(
                to: #selector(STPPaymentCardTextField.formTextFieldDidBackspace(onEmpty:))) ?? false
            {
                formDelegate?.formTextFieldDidBackspace?(onEmpty: self)
            }
        }
    }

    /// :nodoc:
    @objc public override var text: String? {
        get {
            return super.text
        }
        set(text) {
            let nonNilText = text ?? ""
            _didSetText(text: nonNilText)
        }
    }
    func _didSetText(text: String) {
        let attributed = NSAttributedString(string: text, attributes: defaultTextAttributes)
        attributedText = attributed
    }

    /// :nodoc:
    @objc public override var attributedText: NSAttributedString? {
        get {
            return super.attributedText
        }
        set(attributedText) {
            let oldValue = self.attributedText
            let shouldModify =
                formDelegate != nil
                && formDelegate?.responds(
                    to: #selector(
                        STPFormTextFieldDelegate.formTextField(_:modifyIncomingTextChange:)))
                    ?? false
            var modified: NSAttributedString?
            if let attributedText = attributedText {
                modified =
                    shouldModify
                    ? formDelegate?.formTextField?(self, modifyIncomingTextChange: attributedText)
                    : attributedText
            }
            let transformed = textFormattingBlock != nil ? textFormattingBlock?(modified) : modified
            super.attributedText = transformed
            sendActions(for: .editingChanged)
            if formDelegate?.responds(
                to: #selector(STPPaymentCardTextField.formTextFieldTextDidChange(_:))) ?? false
            {
                if let oldValue = oldValue {
                    if !(transformed?.isEqual(to: oldValue) ?? false) {
                        formDelegate?.formTextFieldTextDidChange?(self)
                    }
                }
            }
        }
    }

    @objc public override var accessibilityAttributedValue: NSAttributedString? {
        get {
            guard let text = text else {
                return nil
            }
            let attributedString = NSMutableAttributedString(string: text)
            if #available(iOS 13.0, *) {
                attributedString.addAttribute(
                    .accessibilitySpeechSpellOut, value: NSNumber(value: true),
                    range: NSRange(location: 0, length: attributedString.length))
            }
            return attributedString
        }
        set {
            // do nothing
        }
    }

    @objc public override var accessibilityAttributedLabel: NSAttributedString? {
        get {
            guard let accessibilityLabel = accessibilityLabel else {
                return nil
            }
            let attributedString = NSMutableAttributedString(string: accessibilityLabel)
            if !validText {
                let invalidData = STPLocalizedString(
                    "Invalid data.",
                    "Spoken during VoiceOver when a form field has failed validation.")
                let failedString = NSMutableAttributedString(
                    string: invalidData,
                    attributes: [
                        NSAttributedString.Key.accessibilitySpeechPitch: NSNumber(value: 0.6)
                    ])
                attributedString.append(NSAttributedString(string: " "))
                attributedString.append(failedString)
            }
            return attributedString
        }
        set {
            // do nothing
        }
    }

    /// :nodoc:
    @objc public override var attributedPlaceholder: NSAttributedString? {
        get {
            return super.attributedPlaceholder
        }
        set(attributedPlaceholder) {
            _didSetAttributedPlaceholder(attributedPlaceholder: attributedPlaceholder)
        }
    }
    func _didSetAttributedPlaceholder(attributedPlaceholder: NSAttributedString?) {
        let transformed =
            textFormattingBlock != nil
            ? textFormattingBlock?(attributedPlaceholder) : attributedPlaceholder
        super.attributedPlaceholder = transformed
    }

    // Fixes a weird issue related to our custom override of deleteBackwards. This only affects the simulator and iPads with custom keyboards.
    /// :nodoc:
    @objc public override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(
                input: "\u{08}", modifierFlags: .command, action: #selector(commandDeleteBackwards))
        ]
    }

    @objc func commandDeleteBackwards() {
        text = ""
    }

    /// :nodoc:
    @objc
    public override func closestPosition(to point: CGPoint) -> UITextPosition? {
        if selectionEnabled {
            return super.closestPosition(to: point)
        }
        return position(from: beginningOfDocument, offset: text?.count ?? 0)
    }

    /// :nodoc:
    @objc
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return super.canPerformAction(action, withSender: sender) && action == #selector(paste(_:))
    }

    /// :nodoc:
    @objc
    public override func paste(_ sender: Any?) {
        if preservesContentsOnPaste {
            super.paste(sender)
        } else if autoFormattingBehavior == .expiration {
            text = STPStringUtils.expirationDateString(from: UIPasteboard.general.string)
        } else {
            text = UIPasteboard.general.string
        }
    }

    /// :nodoc:
    @objc public override weak var delegate: UITextFieldDelegate? {
        get {
            super.delegate
        }
        set {
            let dProxy = STPTextFieldDelegateProxy()
            dProxy.autoformattingBehavior = autoFormattingBehavior
            dProxy.selectionEnabled = selectionEnabled
            self.delegateProxy = dProxy
            super.delegate = newValue
        }
    }
}

class STPTextFieldDelegateProxy: NSObject, UITextFieldDelegate {
    internal var inShouldChangeCharactersInRange = false
    var autoformattingBehavior: STPFormTextFieldAutoFormattingBehavior = .none
    var selectionEnabled = false

    func textField(
        _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if inShouldChangeCharactersInRange {
            // This guards against infinite recursion that happens when moving the cursor
            return true
        }
        inShouldChangeCharactersInRange = true

        let insertingIntoEmptyField =
            (textField.text?.count ?? 0) == 0 && range.location == 0 && range.length == 0
        let hasTextContentType = textField.textContentType != nil

        if hasTextContentType && insertingIntoEmptyField && (string == " ") {
            /* Observed behavior w/iOS 11.0 through 11.2.0 (latest):

                     1. UITextContentType suggestions are only available when textField is empty
                     2. When user taps a QuickType suggestion for the `textContentType`, UIKit *first*
                     calls this method with `range:{0, 0} replacementString:@" "`
                     3. If that succeeds (we return YES), this method is called again, this time with
                     the actual content to insert (and a space at the end)

                     Therefore, always allow entry of a single space in order to support `textContentType`.

                     Warning: This bypasses `setText:`, and subsequently `setAttributedText:` and the
                     formDelegate methods: `formTextField:modifyIncomingTextChange:` & `formTextFieldTextDidChange:`
                     That's acceptable for a single space.
                     */
            inShouldChangeCharactersInRange = false
            return true
        }

        let deleting =
            range.location == (textField.text?.count ?? 0) - 1 && range.length == 1
            && (string == "")
        var inputText: String?
        if deleting {
            if let sanitized = unformattedString(for: textField.text) {
                inputText = sanitized.stp_safeSubstring(to: sanitized.count - 1)
            }
        } else {
            let newString = (textField.text as NSString?)?.replacingCharacters(
                in: range, with: string)
            // Removes any disallowed characters from the whole string.
            // If we (incorrectly) allowed a space to start the text entry hoping it would be a
            // textContentType completion, this will remove it.
            let sanitized = unformattedString(for: newString)
            inputText = sanitized
        }

        let beginning = textField.beginningOfDocument
        let start = textField.position(from: beginning, offset: range.location)

        if textField.text == inputText {
            inShouldChangeCharactersInRange = false
            return false
        }

        textField.text = inputText

        if autoformattingBehavior == .none && selectionEnabled {

            // this will be the new cursor location after insert/paste/typing
            var cursorOffset: Int?
            if let start = start {
                cursorOffset = textField.offset(from: beginning, to: start) + string.count
            }

            let newCursorPosition = textField.position(
                from: textField.beginningOfDocument, offset: cursorOffset ?? 0)
            var newSelectedRange: UITextRange?
            if let newCursorPosition = newCursorPosition {
                newSelectedRange = textField.textRange(
                    from: newCursorPosition, to: newCursorPosition)
            }
            textField.selectedTextRange = newSelectedRange
        }

        inShouldChangeCharactersInRange = false
        return false
    }

    func unformattedString(for string: String?) -> String? {
        switch autoformattingBehavior {
        case .none:
            return string
        case .cardNumbers, .phoneNumbers, .expiration, .bsbNumber:
            return STPCardValidator.sanitizedNumericString(for: string ?? "")
        }
    }
}

typealias STPFormTextTransformationBlock = (NSAttributedString?) -> NSAttributedString
