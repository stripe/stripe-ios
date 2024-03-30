//
//  MultilineIconLabelHTMLView.swift
//  StripeIdentity
//
//  Created by Chen Cen on 9/20/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class MultilineIconLabelHTMLView: UIView {
    typealias LineContent = (icon: StripeAPI.VerificationPageIconType, content: String)
    struct ViewModel {
        let lines: [LineContent]
        let didOpenURL: (URL) -> Void
    }

    private let vStack: UIStackView = {
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.distribution = .fill
        vStack.alignment = .leading
        vStack.spacing = 24
        return vStack
    }()

    init() {
        super.init(frame: .zero)
        addAndPinSubview(vStack)
    }

    func configure(with viewModel: ViewModel) throws {
        try viewModel.lines.forEach { line in
            let newLine = IconLabelHTMLView()
            try newLine.configure(
                with: .init(
                    image: line.icon.makeImage(),
                    text: line.content,
                    style: .html(makeStyle: MultilineIconLabelHTMLView.multiLineContentStyle),
                    didOpenURL: viewModel.didOpenURL
                )
            )
            vStack.addArrangedSubview(newLine)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func multiLineContentStyle() -> HTMLStyle {
        let boldFont = IdentityUI.preferredFont(forTextStyle: UIFont.TextStyle.body, weight: .bold)
        let contentColor = IdentityUI.htmlLineTextColor
        return .init(
            bodyFont: IdentityUI.preferredFont(forTextStyle: UIFont.TextStyle.body),
            bodyColor: contentColor,
            h1Font: boldFont,
            h2Font: boldFont,
            h3Font: boldFont,
            h4Font: boldFont,
            h5Font: boldFont,
            h6Font: boldFont,
            isLinkUnderlined: true,
            shouldCenterText: false,
            linkColor: contentColor
        )
    }
}
