//
//  IdentityHTMLView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/11/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class IdentityHTMLView: UIView {

    struct Styling {
        static let iconTextSpacing: CGFloat = 8
        static let verticalSpacing: CGFloat = 24

        static var iconLabelFont: UIFont {
            return IdentityUI.preferredFont(forTextStyle: .body)
        }

        static var htmlStyle: HTMLStyle {
            let boldBody = IdentityUI.preferredFont(forTextStyle: .body, weight: .bold)
            return .init(
                bodyFont: IdentityUI.preferredFont(forTextStyle: .body),
                bodyColor: UILabel.appearance().textColor ?? CompatibleColor.label,
                h1Font: boldBody,
                h2Font: boldBody,
                h3Font: boldBody,
                h4Font: boldBody,
                h5Font: boldBody,
                h6Font: boldBody,
                isLinkUnderlined: false
            )
        }
    }

    struct ViewModel {
        struct IconText {
            let image: UIImage
            let text: String
        }

        let iconText: IconText?
        let htmlString: String
        let didOpenURL: (URL) -> Void
    }

    // MARK: Views

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        return imageView
    }()

    private let iconLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = Styling.iconLabelFont
        return label
    }()

    private lazy var textView: UITextView = {
        let textView: UITextView

        // iOS 13 requires that the TextView be editable for links to open but
        // iOS 14 does not.
        if #available(iOS 14, *) {
            textView = UITextView()
            textView.isEditable = false
        } else {
            // Remove the spelling rotor so the voice over doesn't say,
            // "use the rotor to access misspelled words"
            textView = TextViewWithoutSpellingRotor()
            // Tell the voice over engine that this is static text so it doesn't
            // say, "double tap to edit"
            textView.accessibilityTraits = .staticText
        }

        textView.isScrollEnabled = false
        textView.backgroundColor = nil
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.adjustsFontForContentSizeCategory = true
        textView.delegate = self
        return textView
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = IdentityUI.separatorColor
        return view
    }()

    private let iconTextStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = Styling.iconTextSpacing
        return stackView
    }()

    private let vStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = Styling.verticalSpacing
        return stackView
    }()

    // MARK: - Properties

    private var htmlString = ""
    private var didOpenURL: (URL) -> Void = { _ in }

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        installViews()
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(with viewModel: ViewModel) throws {
        if let iconTextViewModel = viewModel.iconText {
            iconView.image = iconTextViewModel.image
            iconLabel.text = iconTextViewModel.text
            iconTextStack.isHidden = false
            separatorView.isHidden = false
        } else {
            iconTextStack.isHidden = true
            separatorView.isHidden = true
        }

        // Cache the HTML so we can re-generate the attributedText at a new font size
        self.htmlString = viewModel.htmlString

        textView.attributedText = try NSAttributedString(
            htmlText: viewModel.htmlString,
            style: Styling.htmlStyle
        )
        self.didOpenURL = viewModel.didOpenURL
    }

    // MARK: UIView

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Recompute attributed text with updated font sizes
        guard let attributedText = try? NSAttributedString(
            htmlText: htmlString,
            style: Styling.htmlStyle
        ) else {
            return
        }

        textView.attributedText = attributedText
    }
}

private extension IdentityHTMLView {
    func installViews() {
        addAndPinSubview(vStack)
        iconTextStack.addArrangedSubview(iconView)
        iconTextStack.addArrangedSubview(iconLabel)
        vStack.addArrangedSubview(iconTextStack)
        vStack.addArrangedSubview(separatorView)
        vStack.addArrangedSubview(textView)
    }

    func installConstraints() {
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            separatorView.heightAnchor.constraint(equalToConstant: IdentityUI.separatorHeight)
        ])
    }
}

extension IdentityHTMLView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
        didOpenURL(url)
        return false
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        // textView.isEditable must be true for links to be able to be opened,
        // so always return false to disable editability
        return false
    }
}

/// A UITextView without the misspelled words rotor
private class TextViewWithoutSpellingRotor: UITextView {
    override var accessibilityCustomRotors: [UIAccessibilityCustomRotor]? {
        get {
            // Removes the misspelled word rotor from the accessibility rotors
            return super.accessibilityCustomRotors?.filter { $0.systemRotorType != .misspelledWord }
        }
        set {
            super.accessibilityCustomRotors = newValue
        }
    }
}
