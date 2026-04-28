//
//  RowButtonSublabel.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
import UIKit

protocol RowButtonSublabel: AnyObject {
    var view: UIView { get }
    var hasVisibleContent: Bool { get }

    func attach(to rowButton: RowButton)
    func updateSelectedState(isSelected: Bool)
    func updateHeightConstraint()
}

final class RowButtonPlainSublabel: RowButtonSublabel {
    let label: UILabel
    private weak var rowButton: RowButton?

    var view: UIView {
        return label
    }

    var hasVisibleContent: Bool {
        guard let text = label.text else {
            return false
        }
        return !text.isEmpty
    }

    init(text: String?, appearance: PaymentSheet.Appearance, isEmbedded: Bool) {
        self.label = RowButton.makeRowButtonSublabel(text: text, appearance: appearance, isEmbedded: isEmbedded)
    }

    func attach(to rowButton: RowButton) {
        self.rowButton = rowButton
    }

    func setSublabel(text: String?, animated: Bool = true) {
        guard let rowButton, text != label.text else {
            return
        }
        let duration = animated ? 0.2 : 0
        guard let text else {
            UIView.animate(withDuration: duration) {
                self.label.text = nil
                self.label.isHidden = true
                rowButton.setNeedsLayout()
                rowButton.layoutIfNeeded()
            }
            return
        }

        label.text = text
        label.alpha = 0
        UIView.animate(withDuration: duration) {
            self.label.isHidden = text.isEmpty
        }
        UIView.animate(withDuration: duration / 2, delay: duration / 2) {
            self.label.alpha = 1
        }
    }

    func updateSelectedState(isSelected: Bool) {
        // No-op for the plain variant.
    }

    func updateHeightConstraint() {
        guard let rowButton else {
            return
        }

        if rowButton.isFlatWithCheckmarkOrChevronStyle && rowButton.isDisplayingAccessoryView {
            rowButton.heightConstraint?.isActive = false
            return
        }

        guard !hasVisibleContent else {
            rowButton.heightConstraint?.isActive = false
            return
        }

        rowButton.heightConstraint?.isActive = false
        rowButton.heightConstraint = rowButton.heightAnchor.constraint(
            equalToConstant: RowButton.calculateTallestHeight(appearance: rowButton.appearance, isEmbedded: rowButton.isEmbedded)
        )
        rowButton.heightConstraint?.isActive = true
    }
}

struct RowButtonBNPLData {
    let promotion: String
    let learnMoreText: String
    let infoURL: URL
}

final class RowButtonBNPLSublabel: RowButtonSublabel {
    let bnplData: RowButtonBNPLData
    let textView: UITextView
    private weak var rowButton: RowButton?

    var view: UIView {
        return textView
    }

    var hasVisibleContent: Bool {
        return !(textView.attributedText?.string.isEmpty ?? true)
    }

    init(
        attributedText: NSAttributedString? = nil,
        bnplData: RowButtonBNPLData,
        appearance: PaymentSheet.Appearance,
        isEmbedded: Bool
    ) {
        self.bnplData = bnplData
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.adjustsFontForContentSizeCategory = true
        textView.attributedText = attributedText
        textView.isHidden = attributedText == nil || attributedText?.string.isEmpty == true

        let textColor: UIColor = {
            guard isEmbedded else {
                return appearance.colors.componentPlaceholderText
            }

            switch appearance.embeddedPaymentElement.row.style {
            case .flatWithRadio, .flatWithCheckmark, .flatWithDisclosure:
                return appearance.colors.textSecondary
            case .floatingButton:
                return appearance.colors.componentPlaceholderText
            }
        }()

        textView.textColor = textColor
        self.textView = textView
    }

    func attach(to rowButton: RowButton) {
        self.rowButton = rowButton
    }

    func updateSelectedState(isSelected: Bool) {
        // BNPL-specific selected-state behavior will be implemented later.
    }

    func updateHeightConstraint() {
        rowButton?.heightConstraint?.isActive = false
    }
}
