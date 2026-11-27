//
//  PickerFieldView.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 10/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripeCore
import UIKit

/**
 An input field that looks like TextFieldView but presents a menu when tapped.

 - Note: This view has padding according to `directionalLayoutMargins`.
 For internal SDK use only
 */
@objc(STP_Internal_PickerFieldView)
final class PickerFieldView: UIView {

    /// A button overlaid on the field that presents its menu
    final class MenuButton: UIButton {
        // Allows programmatic navigation to focus the button without opening its menu
        override var canBecomeFirstResponder: Bool { true }

        override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            // Dismiss the keyboard of the previously focused field so it doesn't stay up behind the menu
            window?.endEditing(true)
            return super.beginTracking(touch, with: event)
        }

        override func accessibilityActivate() -> Bool {
            window?.endEditing(true)
            return super.accessibilityActivate()
        }
    }

    // MARK: - Views
    private lazy var textField: PickerTextField = {
        let textField = PickerTextField()
        textField.adjustsFontForContentSizeCategory = true
        textField.font = theme.fonts.subheadline
        textField.delegate = self
        return textField
    }()
    private lazy var floatingPlaceholderTextFieldView: FloatingPlaceholderTextFieldView? = {
        guard let label = label else {
            return nil
        }
        let floatingPlaceholderView = FloatingPlaceholderTextFieldView(textField: textField, theme: theme)
        floatingPlaceholderView.placeholder = label
        return floatingPlaceholderView
    }()
    private lazy var chevronImageView: UIImageView? = {
        guard shouldShowChevron else {
            return nil
        }
        let imageView = UIImageView(image: Image.icon_chevron_down.makeImage().withRenderingMode(.alwaysTemplate))
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        if isOptional {
            imageView.image = imageView.image?.resized(to: 0.75)?.withRenderingMode(.alwaysTemplate)
        }
        imageView.tintColor = isOptional ? theme.colors.placeholderText : theme.colors.textFieldText
        return imageView
    }()
    private lazy var hStackView: UIStackView = {
        let hStackView = UIStackView(
            arrangedSubviews: [floatingPlaceholderTextFieldView ?? textField, chevronImageView].compactMap { $0 }
        )
        hStackView.alignment = .center
        if isOptional {
            hStackView.spacing = 3
        } else {
            hStackView.spacing = 6
        }
        return hStackView
    }()
    private let menuButton: MenuButton

    // MARK: - Other private properties
    private let label: String?
    private let shouldShowChevron: Bool
    private let theme: ElementsAppearance
    // When a PickerFieldView is optional it's chevron is smaller and takes the color of placeholder text
    private let isOptional: Bool
    private var _canBecomeFirstResponder = true

    // MARK: - Public properties
    var displayText: NSAttributedString? {
        get {
            return textField.attributedText
        }
        set {
            if newValue != textField.attributedPlaceholder {
                invalidateIntrinsicContentSize()
            }
            textField.attributedText = newValue
            // Unfortunate hack for card brand choice to show card brand logos
            // UITextField doesn't render attributed text with text attachments for some reason
            // But it works when setting it's placeholder text
            // https://stackoverflow.com/questions/54804809/cant-add-image-as-nstextattachment-to-uitextfield
            if (newValue?.hasTextAttachment ?? false) && newValue?.length == 1 {
                textField.attributedPlaceholder = newValue
            }
        }
    }

    var displayTextAccessibilityValue: String? {
        get {
            return textField.accessibilityValue
        }
        set {
            textField.accessibilityValue = newValue
        }
    }

    // MARK: - Initializers

    /**
     - Parameter label: The label of this picker
     - Parameter shouldShowChevron: Whether a downward chevron should be displayed in this field
     - Parameter menuButton: The button that presents the menu when this field is tapped
     - Parameter theme: Theme for the picker field
     */
    init(
        label: String?,
        shouldShowChevron: Bool,
        menuButton: MenuButton,
        theme: ElementsAppearance,
        hasPadding: Bool = true,
        isOptional: Bool = false
    ) {
        self.label = label
        self.shouldShowChevron = shouldShowChevron
        self.menuButton = menuButton
        self.theme = theme
        self.isOptional = isOptional
        super.init(frame: .zero)
        addAndPinSubview(hStackView, directionalLayoutMargins: hasPadding ? theme.textFieldInsets : .zero)
        addAndPinSubview(menuButton, directionalLayoutMargins: theme.textFieldInsets)
        // The menu button is the accessibility element, so VoiceOver activation presents the menu
        hStackView.accessibilityElementsHidden = true
        layer.borderColor = theme.colors.border.cgColor
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTextAlignment()
        floatingPlaceholderTextFieldView?.updatePlaceholder(animated: false)
    }

    private func updateTextAlignment() {
        textField.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .natural
    }

    override var isUserInteractionEnabled: Bool {
        didSet {
            menuButton.isEnabled = isUserInteractionEnabled
            textField.textColor = theme.colors.textFieldText.disabled(!isUserInteractionEnabled)
            if frame.size != .zero {
                textField.layoutIfNeeded()  // Fixes an issue on iOS 15 where setting textField properties causes it to lay out from zero size.
            }
        }
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderColor = theme.colors.border.cgColor
        // Update the text attachment images for the attributed placeholder
        textField.attributedPlaceholder = textField.attributedPlaceholder?.switchAttachments(for: .current)
    }
#endif

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, self.point(inside: point, with: event) else {
            return nil
        }
        // Forward all events within our bounds to the menu button
        return menuButton
    }

    override var intrinsicContentSize: CGSize {
        // I'm implementing this to disambiguate layout of a horizontal stack view containing this view
        let hStackViewSize = hStackView.systemLayoutSizeFitting(.zero)
        return CGSize(
            width: hStackViewSize.width + directionalLayoutMargins.leading + directionalLayoutMargins.trailing,
            height: hStackViewSize.height + directionalLayoutMargins.top + directionalLayoutMargins.bottom
        )
    }

    override func becomeFirstResponder() -> Bool {
        // Prevents unwanted invocation of the picker's `becomeFirstResponder` method.
        // Sometimes, when the picker is added as a subview or when its `isUserInteractionEnabled` is toggled,
        // the operating system mistakenly calls `becomeFirstResponder`, which would end editing in the focused field.
        guard _canBecomeFirstResponder, isUserInteractionEnabled else {
            return false
        }

        // Focus the menu button without opening the menu, and dismiss the keyboard of the previously focused field
        window?.endEditing(true)
        guard menuButton.becomeFirstResponder() else {
            return false
        }
        UIAccessibility.post(notification: .layoutChanged, argument: menuButton)
        return true
    }

    func setCanBecomeFirstResponder(_ value: Bool) {
        _canBecomeFirstResponder = value
    }

    override func resignFirstResponder() -> Bool {
        return menuButton.resignFirstResponder()
    }
}

// MARK: - EventHandler

extension PickerFieldView: EventHandler {
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            isUserInteractionEnabled = true
        case .shouldDisableUserInteraction:
            isUserInteractionEnabled = false
        default:
            break
        }
    }
}

// MARK: - UITextFieldDelegate

extension PickerFieldView: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // The text field only displays the selection; the menu button handles input
        return false
    }
}
