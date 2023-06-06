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
        textField.textColor = .textPrimary
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
                .foregroundColor: UIColor.textSecondary,
                .font: FinancialConnectionsFont.label(.large).uiFont,
            ]
        )
        textField.returnKeyType = .search
        textField.delegate = self
        textField.addTarget(
            self,
            action: #selector(textFieldTextDidChange),
            for: .editingChanged
        )
        textField.accessibilityIdentifier = "search_bar_text_field"
        return textField
    }()
    private lazy var textFieldClearButton: UIButton = {
        let imageView = UIImageView()
        let textFieldClearButton = TextFieldClearButton()
        let cancelImage = Image.cancel_circle.makeImage()
            .withTintColor(.textDisabled)
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
            .withTintColor(.textPrimary)
        searchIconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchIconImageView.widthAnchor.constraint(equalToConstant: 16),
            searchIconImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
        return searchIconImageView
    }()

    init() {
        super.init(frame: .zero)
        layer.cornerRadius = 8

        let horizontalStackView = UIStackView(
            arrangedSubviews: [
                searchIconView,
                textField,
                textFieldClearButton,
            ]
        )
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center
        horizontalStackView.spacing = 10
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

    @discardableResult override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    @objc private func textFieldTextDidChange() {
        adjustClearButtonVisibility()
        delegate?.institutionSearchBar(self, didChangeText: text)
    }

    @objc private func didSelectClearButton() {
        text = ""
    }

    private func adjustClearButtonVisibility() {
        textFieldClearButton.isHidden = text.isEmpty
    }

    private func highlightBorder(_ shouldHighlightBorder: Bool) {
        let searchBarBorderColor: UIColor
        let searchBarBorderWidth: CGFloat
        if shouldHighlightBorder {
            searchBarBorderColor = .textBrand
            searchBarBorderWidth = 2
        } else {
            searchBarBorderColor = .borderNeutral
            searchBarBorderWidth = 1
        }
        layer.borderColor = searchBarBorderColor.cgColor
        layer.borderWidth = searchBarBorderWidth
    }

    func updateSearchingIndicator(_ isSearching: Bool) {
        guard isSearching else {
            searchIconView.layer.removeAnimation(forKey: "pulseAnimation")
            return
        }
        guard searchIconView.layer.animation(forKey: "pulseAnimation") == nil else {
            return
        }

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.6
        opacityAnimation.toValue = 0.3
        opacityAnimation.repeatCount = .infinity
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        opacityAnimation.duration = 0.3
        opacityAnimation.autoreverses = true
        searchIconView.layer.add(opacityAnimation, forKey: "pulseAnimation")
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

    func makeUIView(context: Context) -> InstitutionSearchBar {
        InstitutionSearchBar()
    }

    func updateUIView(_ searchBar: InstitutionSearchBar, context: Context) {
        searchBar.text = text
    }
}

struct InstitutionSearchBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            InstitutionSearchBarUIViewRepresentable(text: "")
                .frame(width: 327)
                .frame(height: 56)

            InstitutionSearchBarUIViewRepresentable(text: "Chase")
                .frame(width: 327)
                .frame(height: 56)

            Spacer()
        }
        .frame(maxWidth: .infinity)
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
