//
//  HTMLViewWithIconLabels.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/11/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class HTMLViewWithIconLabels: UIView {

    struct Styling {
        static let iconTextSpacing: CGFloat = 8
        static let verticalIconTextSpacing: CGFloat = 12
        static let verticalSeparatorSpacing: CGFloat = 16

        private static let iconLabelTextStyle = UIFont.TextStyle.caption1
        private static let bodyTextStyle = UIFont.TextStyle.body
    }

    struct ViewModel {
        struct IconText {
            let image: UIImage
            let text: String
            let isTextHTML: Bool
        }

        let iconText: [IconText]
        let bodyHtmlString: String
        let didOpenURL: (URL) -> Void

        var bodyTextViewModel: HTMLTextView.ViewModel {
            return .init(
                text: bodyHtmlString,
                style: .html(makeStyle: Styling.bodyTextHTMLStyle),
                didOpenURL: didOpenURL
            )
        }

        var iconLabelViewModels: [IconLabelHTMLView.ViewModel] {
            return iconText.map { .init(
                image: $0.image,
                text: $0.text,
                isTextHTML: $0.isTextHTML,
                didOpenURL: didOpenURL
            )}
        }
    }

    // MARK: Views

    private let textView = HTMLTextView()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = IdentityUI.separatorColor
        return view
    }()

    private let vStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = Styling.verticalSeparatorSpacing
        return stackView
    }()

    private var iconLabelViews: [IconLabelHTMLView] = []

    // MARK: - Properties

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
        try textView.configure(with: viewModel.bodyTextViewModel)
        try rebuildIconTextViews(for: viewModel.iconLabelViewModels)
        self.didOpenURL = viewModel.didOpenURL
    }
}

// MARK: - Private Helpers

private extension HTMLViewWithIconLabels {
    func installViews() {
        addAndPinSubview(vStack)
        vStack.addArrangedSubview(separatorView)
        vStack.addArrangedSubview(textView)
    }

    func installConstraints() {
        NSLayoutConstraint.activate([
            separatorView.heightAnchor.constraint(equalToConstant: IdentityUI.separatorHeight)
        ])
    }

    func rebuildIconTextViews(for viewModels: [IconLabelHTMLView.ViewModel]) throws {
        iconLabelViews.forEach { $0.removeFromSuperview() }

        separatorView.isHidden = viewModels.isEmpty

        iconLabelViews = try viewModels.enumerated().map { index, viewModel in
            let view = IconLabelHTMLView()
            try view.configure(with: viewModel)
            vStack.insertArrangedSubview(view, at: index)
            vStack.setCustomSpacing(Styling.verticalIconTextSpacing, after: view)
            return view
        }
    }
}

// MARK: - Styling

extension HTMLViewWithIconLabels.Styling {
    static var iconLabelFont: UIFont {
        return IdentityUI.preferredFont(forTextStyle: iconLabelTextStyle)
    }

    static var bodyTextFont: UIFont {
        return IdentityUI.preferredFont(forTextStyle: bodyTextStyle)
    }

    static func iconLabelHTMLStyle() -> HTMLStyle {
        return htmlStyle(for: iconLabelTextStyle)
    }

    static func bodyTextHTMLStyle() -> HTMLStyle {
        return htmlStyle(for: bodyTextStyle)
    }

    private static func htmlStyle(for textStyle: UIFont.TextStyle) -> HTMLStyle {
        let boldFont = IdentityUI.preferredFont(forTextStyle: textStyle, weight: .bold)
        return .init(
            bodyFont: IdentityUI.preferredFont(forTextStyle: textStyle),
            bodyColor: UILabel.appearance().textColor ?? CompatibleColor.label,
            h1Font: boldFont,
            h2Font: boldFont,
            h3Font: boldFont,
            h4Font: boldFont,
            h5Font: boldFont,
            h6Font: boldFont,
            isLinkUnderlined: false
        )
    }
}
