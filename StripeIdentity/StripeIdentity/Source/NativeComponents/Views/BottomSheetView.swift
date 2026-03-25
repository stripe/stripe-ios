//
//  BottomSheetView.swift
//  StripeIdentity
//
//  Created by Chen Cen on 9/14/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class BottomSheetView: UIView {

    private static let bottomSheetLinePadding: CGFloat = 16
    private static let bottomSheetLineContentPadding: CGFloat = 4
    private static let bottomSheetLineLabelTextStyle = UIFont.TextStyle.body
    private static let bottomSheetCloseButtonInsets = NSDirectionalEdgeInsets(
        top: 8,
        leading: 16,
        bottom: 8,
        trailing: 16
    )
    private static let bottomSheetPadding: CGFloat = 24
    private static let bottomSheetLineTitleSize: CGFloat = 14
    private static let bottomSheetLineContentSize: CGFloat = 14

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .none
        return scrollView
    }()

    private let verticalStack: UIStackView = {
        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.isLayoutMarginsRelativeArrangement = true
        verticalStack.directionalLayoutMargins =
            NSDirectionalEdgeInsets(
                top: bottomSheetPadding, leading: bottomSheetPadding, bottom: bottomSheetPadding, trailing: bottomSheetPadding
            )
        verticalStack.alignment = .leading
        return verticalStack
    }()

    private let closeButton: Button = Button(
        configuration: .identityPrimary(), title: String.Localized.close
    )

    private let closeButtonBackground: UIView = {
        let buttonBackground = UIView()
        buttonBackground.backgroundColor = .systemBackground
        return buttonBackground
    }()

    private let didTapClose: () -> Void

    private let content: BottomSheetViewController.BottomSheetContent

    init(
        content: BottomSheetViewController.BottomSheetContent,
        didTapClose: @escaping () -> Void,
        didOpenURL: @escaping (URL) -> Void
    ) throws {
        self.content = content
        self.didTapClose = didTapClose
        super.init(frame: .zero)
        backgroundColor = IdentityUI.identityElementsUITheme.colors.componentBackground

        closeButton.addTarget(self, action: #selector(tappedClose(button:)), for: .touchUpInside)
        closeButtonBackground.addAndPinSubviewToSafeArea(closeButton, insets: BottomSheetView.bottomSheetCloseButtonInsets)

        installViews()
        try configureVStack(didOpenURL: didOpenURL)
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func tappedClose(button: Button) {
        self.didTapClose()
    }

    private func installViews() {
        scrollView.addAndPinSubview(verticalStack)
        // need to add button later
        addSubview(scrollView)
        addSubview(closeButtonBackground)
    }

    private func installConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        closeButtonBackground.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: calculateContentHeight()),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: closeButtonBackground.topAnchor),
            closeButtonBackground.topAnchor.constraint(equalTo: scrollView.bottomAnchor),
            closeButtonBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            closeButtonBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            closeButtonBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
            // Make scrollView content full width
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),

        ])
    }

    /// Calcualte all paddings added to vertical stack, used to determine height of scrollview
    private func linePaddings() -> CGFloat {
        // start with top and bottom padding
        var padding: CGFloat = BottomSheetView.bottomSheetPadding * 2
        if content.title != nil {
            padding += BottomSheetView.bottomSheetLinePadding

        }

        content.lines.forEach { _ in
            padding += BottomSheetView.bottomSheetLineContentPadding
            padding += BottomSheetView.bottomSheetLinePadding
        }
        return padding
    }

    /// Calculate height of content by adding vertical stack&button and paddings together. If height is over half of screen size, set max height at half of screen size.
    private func calculateContentHeight() -> CGFloat {
        let halfScreenHeight = UIScreen.main.bounds.height/2
        let contentHeight = verticalStack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + linePaddings() + closeButtonBackground.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        return min(halfScreenHeight, contentHeight)
    }

    private func configureVStack(
        didOpenURL: @escaping (URL) -> Void
    ) throws {
        // configure title, can be nil
        if let title = content.title {
            let titleLabel = UILabel()
            titleLabel.font = IdentityUI.preferredFont(forTextStyle: .title2, weight: .bold)
            titleLabel.textColor = IdentityUI.textColor
            titleLabel.accessibilityTraits = [.header]
            titleLabel.text = title
            verticalStack.addArrangedSubview(titleLabel)
            verticalStack.setCustomSpacing(BottomSheetView.bottomSheetLinePadding, after: titleLabel)

        }

        // configure lines
        try content.lines.forEach { line in
            let individualItemStackView = UIStackView()
            individualItemStackView.axis = .horizontal
            individualItemStackView.alignment = .top

            if let icon = line.icon {
                let lineTitleIcon = icon.makeImageView()
                individualItemStackView.addArrangedSubview(lineTitleIcon)
                individualItemStackView.setCustomSpacing(8, after: lineTitleIcon)
            }

            let lineTitleContent = UILabel()
            lineTitleContent.font = IdentityUI.identityElementsUITheme.fonts.subheadlineBold.withSize(BottomSheetView.bottomSheetLineTitleSize)
            lineTitleContent.textColor = IdentityUI.textColor
            lineTitleContent.text = line.title

            let lineContentHTMLTextView = HTMLTextView()
            try lineContentHTMLTextView.configure(
                with: .init(
                    text: line.content,
                    style: .html(makeStyle: BottomSheetView.bottomSheetLineContentStyle),
                    didOpenURL: didOpenURL
                )
            )

            let titleContentVStackView = UIStackView(arrangedSubviews: [lineTitleContent, lineContentHTMLTextView])
            titleContentVStackView.axis = .vertical
            titleContentVStackView.spacing = BottomSheetView.bottomSheetLineContentPadding

            individualItemStackView.addArrangedSubview(titleContentVStackView)

            verticalStack.addArrangedSubview(individualItemStackView)
            verticalStack.setCustomSpacing(BottomSheetView.bottomSheetLinePadding, after: individualItemStackView)
        }

    }

    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners()  // needs to be in `layoutSubviews` to get the correct size for the mask
    }

    private func roundCorners() {
        clipsToBounds = true
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 8, height: 8)
        )
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }

    private static func bottomSheetLineContentStyle() -> HTMLStyle {
        let boldFont = IdentityUI.preferredFont(forTextStyle: BottomSheetView.bottomSheetLineLabelTextStyle, weight: .bold).withSize(bottomSheetLineContentSize)
        let contentColor = IdentityUI.textColor
        return .init(
            bodyFont: IdentityUI.preferredFont(forTextStyle: BottomSheetView.bottomSheetLineLabelTextStyle).withSize(bottomSheetLineContentSize),
            bodyColor: contentColor,
            h1Font: boldFont,
            h2Font: boldFont,
            h3Font: boldFont,
            h4Font: boldFont,
            h5Font: boldFont,
            h6Font: boldFont,
            isLinkUnderlined: true,
            shouldCenterText: false,
            linkColor: contentColor,
            lineHeightMultiple: 1.2
        )
    }

}
