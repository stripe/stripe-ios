//
//  IconLabelHTMLView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/25/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class IconLabelHTMLView: UIView {
    typealias Styling = HTMLViewWithIconLabels.Styling

    // MARK: - ViewModel

    struct ViewModel {
        let image: UIImage
        let text: String
        let isTextHTML: Bool
        let didOpenURL: (URL) -> Void

        var htmlTextViewModel: HTMLTextView.ViewModel {
            let style: HTMLTextView.ViewModel.Style
            if isTextHTML {
                style = .html(makeStyle: Styling.iconLabelHTMLStyle)
            } else {
                style = .plainText(font: Styling.iconLabelFont, textColor: IdentityUI.textColor)
            }

            return .init(
                text: text,
                style: style,
                didOpenURL: didOpenURL
            )
        }
    }

    // MARK: Views

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        return imageView
    }()

    private lazy var textView = HTMLTextView()

    private var iconCenterYConstraint = NSLayoutConstraint()

    // MARK: Init

    init() {
        super.init(frame: .zero)
        installViews()
        installConstraints()
        adjustIconTopConstraint()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Configure

    func configure(with viewModel: ViewModel) throws {
        try textView.configure(with: viewModel.htmlTextViewModel)
        iconView.image = viewModel.image
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // NOTE: `traitCollectionDidChange` is called off the main thread when the app backgrounds
        DispatchQueue.main.async { [weak self] in
            self?.adjustIconTopConstraint()
        }
    }
}

private extension IconLabelHTMLView {
    func installViews() {
        addSubview(iconView)
        addSubview(textView)
    }

    func installConstraints() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false

        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .vertical)
        iconView.setContentHuggingPriority(.required, for: .vertical)

        // Set center-y constraint to lower priority so it isn't unsatisfiable
        // if the font is significantly smaller than the text
        iconCenterYConstraint = iconView.centerYAnchor.constraint(equalTo: topAnchor)
        iconCenterYConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            iconCenterYConstraint,
            iconView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            iconView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconView.trailingAnchor.constraint(equalTo: textView.leadingAnchor, constant: -Styling.iconTextSpacing),
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func adjustIconTopConstraint() {
        // Align the center of the icon with the center of the first line of text
        iconCenterYConstraint.constant = Styling.iconLabelFont.lineHeight / 2
    }
}
