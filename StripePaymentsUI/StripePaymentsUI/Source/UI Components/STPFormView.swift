//
//  STPFormView.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

/// Base protocol to support manually backspacing between form inputs and
/// responding to different inputs receiving/losing focus.
protocol STPFormContainer: NSObjectProtocol {
    func inputTextFieldDidBackspaceOnEmpty(_ textField: STPInputTextField)
    func inputTextFieldWillBecomeFirstResponder(_ textField: STPInputTextField)
    func inputTextFieldDidResignFirstResponder(_ textField: STPInputTextField)
}

/// Internal version of `STPFormViewDelegate` that also includes additional methods for controlling
/// form view interactions.
@_spi(STP) public protocol STPFormViewInternalDelegate: NSObjectProtocol {
    func formView(_ form: STPFormView, didChangeToStateComplete complete: Bool)
    func formViewWillBecomeFirstResponder(_ form: STPFormView)
    func formView(_ form: STPFormView, didTapAccessoryButton button: UIButton)
}

/// Protocol for observing the state of a specific input field within an `STPFormView`.
protocol STPFormInputValidationObserver: NSObjectProtocol {
    func validationDidUpdate(
        to state: STPValidatedInputState,
        from previousState: STPValidatedInputState,
        for unformattedInput: String?,
        in input: STPFormInput
    )
}

/// Protocol for various input types that may be in an `STPFormView`.
protocol STPFormInput where Self: UIView {

    var formContainer: STPFormContainer? { get set }

    var validationState: STPValidatedInputState { get }
    var inputValue: String? { get }

    func addObserver(_ validationObserver: STPFormInputValidationObserver)
    func removeObserver(_ validationObserver: STPFormInputValidationObserver)

    var wantsAutoFocus: Bool { get }

}

/// `STPFormView` is a base class for the Stripe SDK's form input UI. You should use one of the available subclasses
/// (`STPCardFormView`) rather than instantiating an `STPFormView` instance directly.
public class STPFormView: UIView, STPFormInputValidationObserver {

    static let borderlessInset: CGFloat = StackViewWithSeparator.borderlessInset

    let sections: [Section]
    let sectionViews: [SectionView]

    let vStack: UIStackView

    static let borderWidth: CGFloat = 1
    static let cornerRadius: CGFloat = 6
    static let interSectionSpacing: CGFloat = 7

    @_spi(STP) public weak var formViewInternalDelegate: STPFormViewInternalDelegate?

    required init(
        sections: [Section]
    ) {
        self.sections = sections

        vStack = UIStackView()
        var sectionViews = [SectionView]()
        for section in sections {
            let sectionView = SectionView(section: section)
            sectionViews.append(sectionView)
            sectionView.translatesAutoresizingMaskIntoConstraints = false
            vStack.addArrangedSubview(sectionView)
        }

        self.sectionViews = sectionViews
        super.init(frame: .zero)

        vStack.axis = .vertical
        vStack.distribution = .fillProportionally
        vStack.spacing = STPFormView.interSectionSpacing
        vStack.translatesAutoresizingMaskIntoConstraints = false

        sequentialFields.forEach({ $0.formContainer = self })
        addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: vStack.trailingAnchor),
            vStack.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: vStack.bottomAnchor),
        ])
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    func shouldAutoAdvance(
        for input: STPInputTextField,
        with validationState: STPValidatedInputState,
        from previousState: STPValidatedInputState
    ) -> Bool {
        if case .valid = validationState {
            return true
        }
        return false
    }

    func sectionView(for input: STPInputTextField) -> SectionView? {
        return sectionViews.first { (sectionView) -> Bool in
            sectionView.section.contains(input)
        }
    }

    func set(textField: STPInputTextField, isHidden: Bool, animated: Bool) {
        guard isHidden != textField.isHidden,
            let rowView = textField.superview as? UIStackView,
            let sectionView = sectionView(for: textField)
        else {
            return
        }
        var hideContainer = true
        for input in rowView.arrangedSubviews {
            if input == textField {
                if !isHidden {
                    hideContainer = false
                    break
                }
            } else if !input.isHidden {
                hideContainer = false
                break
            }
        }

        if animated {

            if hideContainer != rowView.isHidden {
                if textField.isHidden {
                    textField.alpha = 0
                    textField.isHidden = isHidden
                } else {
                    textField.alpha = 1
                }
            }

            self.setNeedsLayout()
            self.layoutIfNeeded()

            rowView.invalidateIntrinsicContentSize()
            sectionView.stackView.invalidateIntrinsicContentSize()
            UIView.animate(withDuration: 0.2) {
                textField.alpha = isHidden ? 0 : 1
                if hideContainer == rowView.isHidden {
                    textField.isHidden = isHidden
                }
                rowView.isHidden = hideContainer

                rowView.layoutIfNeeded()
                self.setNeedsLayout()
                self.layoutIfNeeded()

            } completion: { (_) in
                textField.isHidden = isHidden
            }

        } else {
            textField.isHidden = isHidden
            rowView.isHidden = hideContainer
        }
    }

    // MARK: - UIResponder
    /// :nodoc:
    @objc
    public override var canResignFirstResponder: Bool {
        if let currentFirstResponderField = currentFirstResponderField() {
            return currentFirstResponderField.canResignFirstResponder
        } else {
            return true
        }
    }

    /// :nodoc:
    @objc
    public override func resignFirstResponder() -> Bool {
        let ret = super.resignFirstResponder()
        if let currentFirstResponderField = currentFirstResponderField() {
            return currentFirstResponderField.resignFirstResponder()
        } else {
            return ret
        }
    }

    /// :nodoc:
    @objc
    public override var isFirstResponder: Bool {
        return super.isFirstResponder || currentFirstResponderField()?.isFirstResponder ?? false
    }

    /// :nodoc:
    @objc
    public override var canBecomeFirstResponder: Bool {
        return sequentialFields.count > 0
    }

    /// :nodoc:
    @objc
    public override func becomeFirstResponder() -> Bool {
        // grab the next first responder before calling super (which will cause any current first responder to resign)
        var firstResponder: STPFormInput?
        if currentFirstResponderField() != nil {
            // we are already first responder, move to next field sequentially
            firstResponder = nextInSequenceFirstResponderField() ?? sequentialFields.first
        } else {
            // Default to the first nonvalid subfield when becoming first responder
            firstResponder = firstNonValidSubField()
        }

        self.formViewInternalDelegate?.formViewWillBecomeFirstResponder(self)
        let ret = super.becomeFirstResponder()
        if let firstResponder = firstResponder {
            return firstResponder.becomeFirstResponder()
        } else {
            return ret
        }
    }

    /// :nodoc:
    @objc
    public override var isUserInteractionEnabled: Bool {
        didSet {
            for sectionView in sectionViews {
                sectionView.isUserInteractionEnabled = isUserInteractionEnabled
            }
        }
    }

    // MARK: - Helpers

    var sequentialFields: [STPFormInput] {
        return sections.reduce(into: [STPFormInput]()) { (result, section) in
            result.append(
                contentsOf: section.rows.reduce(into: [STPInputTextField]()) { (_, row) in
                    for input in row {
                        if !input.isHidden {
                            result.append(input)
                        }
                    }
                }
            )
        }
    }

    func currentFirstResponderField() -> STPFormInput? {
        for field in sequentialFields {
            if field.isFirstResponder {
                return field
            }
        }
        return nil
    }

    func previousField(_ wantsAutoFocusOnly: Bool = false) -> STPFormInput? {
        if let currentFirstResponder = currentFirstResponderField() {
            for (index, field) in sequentialFields.enumerated() {
                if field == currentFirstResponder {
                    var i = index - 1
                    while i >= 0 {
                        let input = sequentialFields[i]
                        if !wantsAutoFocusOnly || (wantsAutoFocusOnly && input.wantsAutoFocus) {
                            return input
                        }
                        i -= 1
                    }
                    return nil
                }
            }
        }
        return nil
    }

    @_spi(STP) public func nextFirstResponderFieldBecomeFirstResponder() {
        nextFirstResponderField()?.becomeFirstResponder()
    }

    func nextFirstResponderField(_ wantsAutoFocusOnly: Bool = false) -> STPFormInput? {
        if let nextField = nextInSequenceFirstResponderField(wantsAutoFocusOnly) {
            return nextField
        } else {
            if currentFirstResponderField() == nil {
                // if we don't currently have a first responder, consider the first non-valid field the next one
                return firstNonValidSubField(wantsAutoFocusOnly)
            } else {
                return lastSubField(wantsAutoFocusOnly)
            }
        }
    }

    func nextInSequenceFirstResponderField(_ wantsAutoFocusOnly: Bool = false) -> STPFormInput? {
        if let currentFirstResponder = currentFirstResponderField() {
            for (index, field) in sequentialFields.enumerated() {
                if field == currentFirstResponder {
                    var i = index + 1
                    while i < sequentialFields.count {
                        let input = sequentialFields[i]
                        if !wantsAutoFocusOnly || (wantsAutoFocusOnly && input.wantsAutoFocus) {
                            return input
                        }
                        i += 1
                    }
                    return nil
                }
            }
        }
        return nil
    }

    func firstNonValidSubField(_ wantsAutoFocusOnly: Bool = false) -> STPFormInput? {
        for field in sequentialFields {
            if case .valid = field.validationState {
                // this field is valid
            } else {
                if !wantsAutoFocusOnly || (wantsAutoFocusOnly && field.wantsAutoFocus) {
                    return field
                }
            }
        }
        return nil
    }

    func lastSubField(_ wantsAutoFocusOnly: Bool = false) -> STPFormInput? {
        for field in sequentialFields.reversed() {
            if !wantsAutoFocusOnly || (wantsAutoFocusOnly && field.wantsAutoFocus) {
                return field
            }
        }
        return nil
    }

    func configureFooter(in sectionView: STPFormView.SectionView) {
        let fields = sectionView.sequentialFields
        let invalidFields = fields.filter { (field) -> Bool in
            if case .invalid = field.validationState {
                return true
            } else {
                return false
            }
        }
        if let firstInvalid = invalidFields.first,
            case .invalid(let errorMessage) = firstInvalid.validationState,
            let nonNilErrorMessage = errorMessage
        {
            sectionView.footerTextColor = InputFormColors.errorColor
            sectionView.footerText = nonNilErrorMessage
            return
        }

        let incompleteFields = fields.filter { (field) -> Bool in
            if case .incomplete = field.validationState, !field.isFirstResponder,
                !(field.inputValue?.isEmpty ?? true)
            {
                return true
            } else {
                return false
            }
        }
        let incompleteFieldsWithMessages = incompleteFields.filter { (field) -> Bool in
            if case .incomplete(let description) = field.validationState, description != nil {
                return true
            } else {
                return false
            }
        }

        if let firstIncomplete = incompleteFieldsWithMessages.first,
            case .incomplete(let description) = firstIncomplete.validationState,
            let nonNilDescription = description
        {
            sectionView.footerTextColor = InputFormColors.errorColor
            sectionView.footerText = nonNilDescription
            return
        }

        if let firstCompleteWithMessageField = fields.first(where: { (field) -> Bool in
            if case .valid(let message) = field.validationState, message != nil {
                return true
            } else {
                return false
            }
        }),
            case .valid(let message) = firstCompleteWithMessageField.validationState,
            let nonNilMessage = message
        {
            sectionView.footerTextColor = .label
            sectionView.footerText = nonNilMessage
            return
        }

        sectionView.footerTextColor = .label
        sectionView.footerText = nil
    }

    // MARK: - STPInputTextFieldValidationObserver

    func validationDidUpdate(
        to state: STPValidatedInputState,
        from previousState: STPValidatedInputState,
        for unformattedInput: String?,
        in input: STPFormInput
    ) {
        guard let textField = input as? STPInputTextField,
            let sectionView = sectionView(for: textField)
        else {
            assertionFailure("Should not receive updates for uncontained inputs")
            return
        }

        let fieldsInSection = sectionView.sequentialFields

        if fieldsInSection.first(where: {
            if case .invalid = $0.validationState {
                return true
            } else {
                return false
            }
        }) != nil {
            sectionView.separatorColor = InputFormColors.errorColor
        } else {
            sectionView.separatorColor = InputFormColors.outlineColor
        }

        configureFooter(in: sectionView)

        if textField == currentFirstResponderField()
            && shouldAutoAdvance(for: textField, with: state, from: previousState)
        {
            if let nextField = nextFirstResponderField(true) {
                _ = nextField.becomeFirstResponder()
                UIAccessibility.post(notification: .screenChanged, argument: nextField)
            }
        }
    }
}

/// :nodoc:
extension STPFormView: STPFormContainer {
    func inputTextFieldDidBackspaceOnEmpty(_ textField: STPInputTextField) {
        guard textField == currentFirstResponderField() else {
            return
        }

        let previous = previousField(true)
        _ = previous?.becomeFirstResponder()
        UIAccessibility.post(notification: .screenChanged, argument: previous)
        if let previousTextField = previous as? STPInputTextField,
            previousTextField.hasText
        {
            previousTextField.deleteBackward()
        }
    }

    func inputTextFieldWillBecomeFirstResponder(_ textField: STPInputTextField) {
        self.formViewInternalDelegate?.formViewWillBecomeFirstResponder(self)

        // Always update on become firstResponder in case some fields
        // were hidden or unhidden
        if textField == lastSubField() {
            textField.returnKeyType = .done
        } else {
            // Note that observed on iOS 14 that setting .next here
            // sometimes messes up the keyboardType for asciiCapableNumberPad
            textField.returnKeyType = .default
        }

        if let sectionView = sectionView(for: textField) {
            configureFooter(in: sectionView)
        }
    }

    func inputTextFieldDidResignFirstResponder(_ textField: STPInputTextField) {
        if let sectionView = sectionView(for: textField) {
            configureFooter(in: sectionView)
        }
    }
}

/// Internal types
extension STPFormView {
    struct Section {
        let rows: [[STPFormInput]]
        let title: String?
        let accessoryButton: UIButton?

        func contains(_ input: STPInputTextField) -> Bool {
            for row in rows.compactMap({ $0 as? [STPInputTextField] }) {
                if row.contains(input) {
                    return true
                }
            }
            return false
        }
    }

    class SectionView: UIView {
        let section: Section

        let stackView: StackViewWithSeparator = StackViewWithSeparator()

        static let titleVerticalMargin: CGFloat = 4

        let footerLabel = UILabel()

        var footerTextColor: UIColor {
            get {
                return footerLabel.textColor
            }
            set {
                footerLabel.textColor = newValue
            }
        }

        var footerText: String? {
            get {
                return footerLabel.text
            }
            set {
                if let newValue = newValue, !newValue.isEmpty {
                    footerLabel.text = newValue
                } else {
                    // We don't want this to ever be empty for sizing reasons
                    footerLabel.text = " "
                }
            }
        }

        var insetFooterLabel: Bool = false {
            didSet {
                footerLabelLeadingConstraint.constant =
                    insetFooterLabel ? STPFormView.borderlessInset : 0
            }
        }

        lazy var footerLabelLeadingConstraint: NSLayoutConstraint = {
            return footerLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
        }()

        @objc
        override var isUserInteractionEnabled: Bool {
            didSet {
                stackView.isUserInteractionEnabled = isUserInteractionEnabled
                for field in sequentialFields {
                    field.isUserInteractionEnabled = isUserInteractionEnabled
                }
            }
        }

        required init(
            section: Section
        ) {
            self.section = section
            let rows = section.rows

            let rowViews = rows.map { (row) -> StackViewWithSeparator in
                let stackView = StackViewWithSeparator(arrangedSubviews: row)
                stackView.axis = .horizontal
                stackView.distribution = .fillEqually
                stackView.translatesAutoresizingMaskIntoConstraints = false
                stackView.spacing = STPFormView.borderWidth
                stackView.separatorColor = InputFormColors.outlineColor
                return stackView
            }

            super.init(frame: .zero)
            for rowView in rowViews {
                stackView.addArrangedSubview(rowView)
            }

            stackView.axis = .vertical
            stackView.distribution = .fillEqually
            stackView.spacing = STPFormView.borderWidth
            stackView.separatorColor = InputFormColors.outlineColor

            stackView.drawBorder = true
            stackView.borderCornerRadius = STPFormView.cornerRadius

            stackView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(stackView)
            var constraints: [NSLayoutConstraint] = [
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            ]

            if let title = section.title {
                let titleLabel = UILabel()
                titleLabel.text = title
                let fontMetrics = UIFontMetrics(forTextStyle: .body)
                titleLabel.font = fontMetrics.scaledFont(
                    for: UIFont.systemFont(ofSize: 13, weight: .semibold)
                )
                titleLabel.textColor = .secondaryLabel
                titleLabel.accessibilityTraits = [.header]

                titleLabel.translatesAutoresizingMaskIntoConstraints = false
                titleLabel.setContentHuggingPriority(.required, for: .vertical)

                var arrangedSubviews: [UIView] = [titleLabel]

                if let button = section.accessoryButton {
                    button.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
                    titleLabel.setContentCompressionResistancePriority(
                        .defaultHigh + 1,
                        for: .horizontal
                    )
                    button.translatesAutoresizingMaskIntoConstraints = false
                    arrangedSubviews.append(button)
                }

                let headerView = UIStackView(arrangedSubviews: arrangedSubviews)
                headerView.translatesAutoresizingMaskIntoConstraints = false
                addSubview(headerView)
                constraints.append(contentsOf: [
                    headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
                    headerView.topAnchor.constraint(equalTo: topAnchor),
                    stackView.topAnchor.constraint(
                        equalTo: headerView.bottomAnchor,
                        constant: SectionView.titleVerticalMargin
                    ),
                ])
            } else {
                constraints.append(stackView.topAnchor.constraint(equalTo: topAnchor))
            }

            footerLabel.translatesAutoresizingMaskIntoConstraints = false
            footerLabel.font = .preferredFont(forTextStyle: .caption1)
            addSubview(footerLabel)
            footerText = " "
            constraints.append(contentsOf: [
                footerLabelLeadingConstraint,
                trailingAnchor.constraint(equalTo: footerLabel.trailingAnchor),
                footerLabel.topAnchor.constraint(
                    equalTo: stackView.bottomAnchor,
                    constant: SectionView.titleVerticalMargin
                ),
                bottomAnchor.constraint(equalTo: footerLabel.bottomAnchor),
            ])

            // the initial layout of a SectionView will log constraint errors if it has a row with multiple
            // inputs because the non-zero spacing conflicts with the default 0 horizontal size. Mark the
            // constraints as priority required-1 to avoid those unhelpful logs
            constraints.forEach({
                $0.priority = UILayoutPriority(rawValue: UILayoutPriority.required.rawValue - 1)
            })
            NSLayoutConstraint.activate(constraints)
            setContentHuggingPriority(.required, for: .vertical)
        }

        required init(
            coder: NSCoder
        ) {
            fatalError("init(coder:) has not been implemented")
        }

        var separatorColor: UIColor = InputFormColors.outlineColor {
            didSet {
                stackView.separatorColor = separatorColor
                for rowView in stackView.arrangedSubviews.compactMap({
                    $0 as? StackViewWithSeparator
                }) {
                    rowView.separatorColor = separatorColor
                }
            }
        }

        var sequentialFields: [STPFormInput] {
            return section.rows.reduce(into: [STPFormInput]()) { (result, row) in
                for input in row {
                    if !input.isHidden {
                        result.append(input)
                    }
                }
            }
        }
    }
}
