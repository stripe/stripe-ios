//
//  HTMLViewWithIconLabels.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class HTMLViewWithIconLabels: UIView {

    struct Styling {
        static let iconTextSpacing: CGFloat = 8
        static let verticalIconTextSpacing: CGFloat = 12
        static let stackViewSpacing: CGFloat = 16
        static let separatorVerticalSpacing: CGFloat = 24

        private static let iconLabelTextStyle = UIFont.TextStyle.caption1
        private static let nonIconLabelTextStyle = UIFont.TextStyle.caption1
        private static let bodyTextStyle = UIFont.TextStyle.body
    }

    struct ViewModel {
        struct IconText {
            let image: UIImage
            let text: String
            let isTextHTML: Bool
        }

        struct NonIconText {
            let text: String
            let isTextHTML: Bool
        }

        var iconText: [IconText] = []
        var nonIconText: [NonIconText] = []

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
            return iconText.map {
                .init(
                    image: $0.image,
                    text: $0.text,
                    isTextHTML: $0.isTextHTML,
                    didOpenURL: didOpenURL
                )
            }
        }

        var nonIconLabelViewModels: [HTMLTextView.ViewModel] {
            return nonIconText.map {
                let style: HTMLTextView.ViewModel.Style
                if $0.isTextHTML {
                    style = .html(makeStyle: Styling.nonIconLabelHTMLStyle)
                } else {
                    style = .plainText(
                        font: Styling.nonIconLabelFont,
                        textColor: IdentityUI.textColor
                    )
                }

                return .init(text: $0.text, style: style, didOpenURL: didOpenURL)
            }
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
        stackView.alignment = .center
        stackView.spacing = Styling.stackViewSpacing
        return stackView
    }()

    private var iconLabelViews: [IconLabelHTMLView] = []
    private var nonIconLabelViews: [HTMLTextView] = []

    // MARK: - Properties

    private var didOpenURL: (URL) -> Void = { _ in }

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        installViews()
        installConstraints()
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(with viewModel: ViewModel) throws {
        try textView.configure(with: viewModel.bodyTextViewModel)
        separatorView.isHidden =
            viewModel.nonIconLabelViewModels.isEmpty && viewModel.iconLabelViewModels.isEmpty
        try rebuildNonIconTextViews(for: viewModel.nonIconLabelViewModels)
        try rebuildIconTextViews(for: viewModel.iconLabelViewModels)
        self.didOpenURL = viewModel.didOpenURL
    }
}

// MARK: - Private Helpers

extension HTMLViewWithIconLabels {
    fileprivate func installViews() {
        addAndPinSubview(vStack)
        vStack.addArrangedSubview(separatorView)
        vStack.addArrangedSubview(textView)
    }

    fileprivate func installConstraints() {
        NSLayoutConstraint.activate([
            separatorView.heightAnchor.constraint(equalToConstant: IdentityUI.separatorHeight),
            separatorView.bottomAnchor.constraint(
                equalTo: textView.topAnchor,
                constant: -Styling.separatorVerticalSpacing
            ),
            separatorView.leadingAnchor.constraint(equalTo: vStack.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: vStack.trailingAnchor),
            textView.leadingAnchor.constraint(equalTo: vStack.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: vStack.trailingAnchor),
        ])
    }

    fileprivate func rebuildIconTextViews(for viewModels: [IconLabelHTMLView.ViewModel]) throws {
        iconLabelViews.forEach { $0.removeFromSuperview() }

        iconLabelViews = try viewModels.enumerated().map { _, viewModel in
            let view = IconLabelHTMLView()
            try view.configure(with: viewModel)
            vStack.insertArrangedSubview(view, at: 0)
            vStack.setCustomSpacing(Styling.verticalIconTextSpacing, after: view)
            return view
        }
    }

    fileprivate func rebuildNonIconTextViews(for viewModels: [HTMLTextView.ViewModel]) throws {
        nonIconLabelViews.forEach { $0.removeFromSuperview() }

        nonIconLabelViews = try viewModels.enumerated().map { index, viewModel in
            let view = HTMLTextView()
            try view.configure(with: viewModel)
            vStack.insertArrangedSubview(view, at: 0)
            if index == viewModels.count - 1 {
                vStack.setCustomSpacing(Styling.separatorVerticalSpacing, after: view)
            } else {
                vStack.setCustomSpacing(Styling.verticalIconTextSpacing, after: view)
            }
            return view
        }
    }
}

// MARK: - Styling

extension HTMLViewWithIconLabels.Styling {
    static var iconLabelFont: UIFont {
        return IdentityUI.preferredFont(forTextStyle: iconLabelTextStyle)
    }

    static var nonIconLabelFont: UIFont {
        return IdentityUI.preferredFont(forTextStyle: nonIconLabelTextStyle)
    }

    static var bodyTextFont: UIFont {
        return IdentityUI.preferredFont(forTextStyle: bodyTextStyle)
    }

    static func iconLabelHTMLStyle() -> HTMLStyle {
        return htmlStyle(for: iconLabelTextStyle)
    }

    static func nonIconLabelHTMLStyle() -> HTMLStyle {
        return htmlStyle(for: nonIconLabelTextStyle, shouldCenterText: true)
    }

    static func bodyTextHTMLStyle() -> HTMLStyle {
        return htmlStyle(for: bodyTextStyle)
    }

    private static func htmlStyle(
        for textStyle: UIFont.TextStyle,
        shouldCenterText ceterText: Bool = false
    ) -> HTMLStyle {
        let boldFont = IdentityUI.preferredFont(forTextStyle: textStyle, weight: .bold)
        return .init(
            bodyFont: IdentityUI.preferredFont(forTextStyle: textStyle),
            bodyColor: IdentityUI.textColor,
            h1Font: boldFont,
            h2Font: boldFont,
            h3Font: boldFont,
            h4Font: boldFont,
            h5Font: boldFont,
            h6Font: boldFont,
            isLinkUnderlined: false,
            shouldCenterText: ceterText
        )
    }
}
