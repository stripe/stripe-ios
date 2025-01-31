//
//  InstitutionSearchBar.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/30/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol InstitutionSearchBarDelegate: AnyObject {
    func institutionSearchBar(
        _ searchBar: InstitutionSearchBar,
        didChangeText text: String
    )
}

final class InstitutionSearchBar: UIView {

    private let appearance: FinancialConnectionsAppearance
    weak var delegate: InstitutionSearchBarDelegate?
    var text: String {
        get {
            return textField.text ?? ""
        }
        set {
            textField.text = newValue
            // manual changes to `text` do not call `textFieldTextDidChange`
            // so here we do it ourselves
            textFieldTextDidChange()
        }
    }

    private lazy var textField: UITextField = {
        let textField = IncreasedHitTestTextField()
        textField.textColor = FinancialConnectionsAppearance.Colors.textDefault
        textField.tintColor = textField.textColor // caret color
        textField.font = FinancialConnectionsFont.label(.large).uiFont
        // this removes the `searchTextField` background color.
        // for an unknown reason, setting the `backgroundColor` to
        // a white color is a no-op
        textField.borderStyle = .none
        // use `NSAttributedString` to be able to change the placeholder color
        textField.attributedPlaceholder = NSAttributedString(
            string: STPLocalizedString(
                "Search",
                "The placeholder message that appears in a search bar. The placeholder appears before a user enters a search term. It instructs user that this is a search bar."
            ),
            attributes: [
                .foregroundColor: FinancialConnectionsAppearance.Colors.textSubdued,
                .font: FinancialConnectionsFont.label(.large).uiFont,
            ]
        )
        textField.returnKeyType = .search
        // fixes a 'bug' where if a user types a keyword, and autocorrect
        // wants to correct it, pressing "search" button will choose
        // the autocorrected word even though the intent was to use the
        // typed-in word
        //
        // also, bank names are not always friendly to autocorrect suggestions
        textField.autocorrectionType = .no
        textField.delegate = self
        textField.addTarget(
            self,
            action: #selector(textFieldTextDidChange),
            for: .editingChanged
        )
        textField.accessibilityIdentifier = "search_bar_text_field"
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
        ])
        return textField
    }()
    private lazy var textFieldClearButton: UIButton = {
        let imageView = UIImageView()
        let textFieldClearButton = TextFieldClearButton()
        let cancelImage = Image.cancel_circle.makeImage()
            .withTintColor(FinancialConnectionsAppearance.Colors.textSubdued)
        textFieldClearButton.setImage(cancelImage, for: .normal)
        textFieldClearButton.addTarget(
            self,
            action: #selector(didSelectClearButton),
            for: .touchUpInside
        )
        textFieldClearButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textFieldClearButton.widthAnchor.constraint(equalToConstant: 16),
            textFieldClearButton.heightAnchor.constraint(equalToConstant: 16),
        ])
        return textFieldClearButton
    }()
    private lazy var searchIconView: UIView = {
        let searchIconImageView = UIImageView()
        searchIconImageView.image = Image.search.makeImage()
            .withTintColor(FinancialConnectionsAppearance.Colors.icon)
        searchIconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchIconImageView.widthAnchor.constraint(equalToConstant: 20),
            searchIconImageView.heightAnchor.constraint(equalToConstant: 20),
        ])
        return searchIconImageView
    }()

    init(appearance: FinancialConnectionsAppearance) {
        self.appearance = appearance
        super.init(frame: .zero)
        layer.cornerRadius = 12

        let horizontalStackView = UIStackView(
            arrangedSubviews: [
                searchIconView,
                textField,
                textFieldClearButton,
            ]
        )
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center
        horizontalStackView.spacing = 12
        horizontalStackView.isLayoutMarginsRelativeArrangement = true
        horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        addAndPinSubview(horizontalStackView)

        highlightBorder(false)
        adjustClearButtonVisibility()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @discardableResult override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    @discardableResult override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    @objc private func textFieldTextDidChange() {
        adjustClearButtonVisibility()
        delegate?.institutionSearchBar(self, didChangeText: text)
    }

    @objc private func didSelectClearButton() {
        FeedbackGeneratorAdapter.buttonTapped()
        text = ""
    }

    private func adjustClearButtonVisibility() {
        textFieldClearButton.isHidden = text.isEmpty
    }

    private func highlightBorder(_ shouldHighlightBorder: Bool) {
        let searchBarBorderColor: UIColor
        let searchBarBorderWidth: CGFloat
        let shadowOpacity: Float
        if shouldHighlightBorder {
            searchBarBorderColor = appearance.colors.textFieldFocused
            searchBarBorderWidth = 2
            shadowOpacity = 0.1
        } else {
            searchBarBorderColor = FinancialConnectionsAppearance.Colors.borderNeutral
            searchBarBorderWidth = 1
            shadowOpacity = 0
        }
        layer.borderColor = searchBarBorderColor.cgColor
        layer.borderWidth = searchBarBorderWidth
        layer.shadowOpacity = shadowOpacity
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 2 / UIScreen.main.nativeScale
        layer.shadowOffset = CGSize(
            width: 0,
            height: 1 / UIScreen.main.nativeScale
        )
    }

    // CGColor's need to be manually updated when the system theme changes.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        layer.shadowColor = FinancialConnectionsAppearance.Colors.shadow.cgColor
    }
}

// MARK: - UITextFieldDelegate

extension InstitutionSearchBar: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        highlightBorder(true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        highlightBorder(false)
    }

    // called when user presses "Search" button in the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

private class IncreasedHitTestTextField: UITextField {
    // increase the area of TextField taps
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let largerBounds = bounds.insetBy(dx: 0, dy: -16)
        return largerBounds.contains(point)
    }
}

#if DEBUG

import SwiftUI

private struct InstitutionSearchBarUIViewRepresentable: UIViewRepresentable {

    let text: String
    var isSelected: Bool = false
    let appearance: FinancialConnectionsAppearance

    func makeUIView(context: Context) -> InstitutionSearchBar {
        InstitutionSearchBar(appearance: appearance)
    }

    func updateUIView(_ searchBar: InstitutionSearchBar, context: Context) {
        searchBar.text = text

        if isSelected {
            _ = searchBar.becomeFirstResponder()
        }
    }
}

struct InstitutionSearchBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            InstitutionSearchBarUIViewRepresentable(text: "", appearance: .stripe)
                .frame(width: 327)
                .frame(height: 56)

            InstitutionSearchBarUIViewRepresentable(text: "Chase", appearance: .stripe)
                .frame(width: 327)
                .frame(height: 56)

            Spacer()
        }
        .frame(maxWidth: .infinity)

        InstitutionSearchBarUIViewRepresentable(text: "Chase", isSelected: true, appearance: .stripe)
            .frame(width: 327)
            .frame(height: 56)
            .previewDisplayName("Selected - Light theme")

        InstitutionSearchBarUIViewRepresentable(text: "Chase", isSelected: true, appearance: .link)
            .frame(width: 327)
            .frame(height: 56)
            .previewDisplayName("Selected - Link Light theme")
    }
}

#endif

private class TextFieldClearButton: UIButton {

    // increase hit-test area of the clear button
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let largerBounds = bounds.insetBy(
            dx: -(50 - bounds.width) / 2,
            dy: -(50 - bounds.height) / 2
        )
        return largerBounds.contains(point)
    }
}
