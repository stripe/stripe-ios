//
//  PaneLayoutView+Header.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 12/22/23.
//

import Foundation
@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

extension PaneLayoutView {

    @available(iOSApplicationExtension, unavailable)
    static func createContentView(
        iconView: UIView?,
        title: String?,
        subtitle: String?,
        contentView: UIView?,
        isSheet: Bool = false
    ) -> UIView {
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 0
        if iconView != nil || title != nil {
            let headerView = createHeaderView(
                iconView: iconView,
                title: title,
                isSheet: isSheet
            )
            verticalStackView.addArrangedSubview(headerView)
        }
        if subtitle != nil || contentView != nil {
            let bodyView = createBodyView(
                text: subtitle,
                contentView: contentView
            )
            verticalStackView.addArrangedSubview(bodyView)
        }
        return verticalStackView
    }

    @available(iOSApplicationExtension, unavailable)
    static func createHeaderView(
        iconView: UIView?,
        title: String?,
        isSheet: Bool = false
    ) -> UIView {
        let headerStackView = HitTestStackView()
        headerStackView.axis = .vertical
        headerStackView.spacing = 16
        headerStackView.alignment = .leading
        if let iconView = iconView {
            headerStackView.addArrangedSubview(iconView)
        }

        if let title = title {
            let titleFont: FinancialConnectionsFont = isSheet ? .heading(.large) : .heading(.extraLarge)
            let titleLabel = AttributedTextView(
                font: titleFont,
                boldFont: titleFont,
                linkFont: titleFont,
                textColor: .textDefault
            )
            titleLabel.setText(title)
            headerStackView.addArrangedSubview(titleLabel)
        }

        let paddingStackView = HitTestStackView(
            arrangedSubviews: [
                headerStackView
            ]
        )
        paddingStackView.isLayoutMarginsRelativeArrangement = true
        paddingStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: isSheet ? 0 : 16, // the sheet handle adds some padding
            leading: Constants.Layout.defaultHorizontalMargin,
            // if there is a subtitle in the "body/content view,"
            // we will add extra "8" padding
            bottom: 16,
            trailing: Constants.Layout.defaultHorizontalMargin
        )
        return paddingStackView
    }

    @available(iOSApplicationExtension, unavailable)
    static func createBodyView(
        text: String?,
        contentView: UIView?
    ) -> UIView {
        let willShowDescriptionText = (text != nil)

        let paddingStackView = HitTestStackView()
        paddingStackView.axis = .vertical
        // add 24 spacing between the text and `contentView`
        paddingStackView.spacing = willShowDescriptionText ? 24 : 0
        paddingStackView.isLayoutMarginsRelativeArrangement = true
        paddingStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            // when we don't show text, add extra 8 spacing
            // to create 24 spacing between "content" and "header"
            // where 16 spacing is already added in `createHeaderView`
            top: willShowDescriptionText ? 0 : 8,
            leading: Constants.Layout.defaultHorizontalMargin,
            bottom: 8,
            trailing: Constants.Layout.defaultHorizontalMargin
        )

        if let text = text {
            let textLabel = AttributedTextView(
                font: .body(.medium),
                boldFont: .body(.mediumEmphasized),
                linkFont: .body(.mediumEmphasized),
                textColor: .textDefault
            )
            textLabel.setText(text)
            paddingStackView.addArrangedSubview(textLabel)
        }

        if let contentView = contentView {
            paddingStackView.addArrangedSubview(contentView)
        }

        return paddingStackView
    }

    struct ButtonConfiguration {
        let title: String
        let accessibilityIdentifier: String?
        let action: () -> Void

        init(
            title: String,
            accessibilityIdentifier: String? = nil,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.accessibilityIdentifier = accessibilityIdentifier
            self.action = action
        }
    }

    @available(iOSApplicationExtension, unavailable)
    static func createFooterView(
        primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration?,
        secondaryButtonConfiguration: PaneLayoutView.ButtonConfiguration? = nil,
        topText: String? = nil,
        didSelectURL: ((URL) -> Void)? = nil
    ) -> (footerView: UIView?, primaryButton: StripeUICore.Button?, secondaryButton: StripeUICore.Button?) {
        guard
            primaryButtonConfiguration != nil || secondaryButtonConfiguration != nil
        else {
            return (nil, nil, nil)  // display no footer
        }
        let footerStackView = FooterStackView(
            didSelectPrimaryButton: primaryButtonConfiguration?.action,
            didSelectSecondaryButton: secondaryButtonConfiguration?.action
        )
        footerStackView.axis = .vertical
        footerStackView.spacing = 8

        if let topText = topText {
            let topTextLabel = AttributedTextView(
                font: .label(.small),
                boldFont: .label(.smallEmphasized),
                linkFont: .label(.small),
                textColor: .textDefault,
                alignCenter: true
            )
            topTextLabel.setText(
                topText,
                action: didSelectURL ?? { _ in }
            )
            footerStackView.addArrangedSubview(topTextLabel)
            footerStackView.setCustomSpacing(16, after: topTextLabel)
        }

        var primaryButtonReference: StripeUICore.Button?
        if let primaryButtonConfiguration = primaryButtonConfiguration {
            let primaryButton = Button.primary()
            primaryButtonReference = primaryButton
            primaryButton.title = primaryButtonConfiguration.title
            primaryButton.accessibilityIdentifier = primaryButtonConfiguration.accessibilityIdentifier
            primaryButton.addTarget(
                footerStackView,
                action: #selector(FooterStackView.didSelectPrimaryButton),
                for: .touchUpInside
            )
            primaryButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                primaryButton.heightAnchor.constraint(equalToConstant: 56)
            ])
            footerStackView.addArrangedSubview(primaryButton)
        }

        var secondaryButtonReference: StripeUICore.Button?
        if let secondaryButtonConfiguration = secondaryButtonConfiguration {
            let secondaryButton = Button.secondary()
            secondaryButtonReference = secondaryButton
            secondaryButton.title = secondaryButtonConfiguration.title
            secondaryButton.accessibilityIdentifier = secondaryButtonConfiguration.accessibilityIdentifier
            secondaryButton.addTarget(
                footerStackView,
                action: #selector(FooterStackView.didSelectSecondaryButton),
                for: .touchUpInside
            )
            secondaryButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                secondaryButton.heightAnchor.constraint(equalToConstant: 56)
            ])
            footerStackView.addArrangedSubview(secondaryButton)
        }

        let paddingStackView = HitTestStackView(
            arrangedSubviews: [
                footerStackView
            ]
        )
        paddingStackView.isLayoutMarginsRelativeArrangement = true
        paddingStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16,
            leading: Constants.Layout.defaultHorizontalMargin,
            bottom: 16,
            trailing: Constants.Layout.defaultHorizontalMargin
        )
        return (paddingStackView, primaryButtonReference, secondaryButtonReference)
    }
}

private class FooterStackView: UIStackView {

    private let didSelectPrimaryButtonHandler: (() -> Void)?
    private let didSelectSecondaryButtonHandler: (() -> Void)?

    init(
        didSelectPrimaryButton: (() -> Void)?,
        didSelectSecondaryButton: (() -> Void)?
    ) {
        self.didSelectPrimaryButtonHandler = didSelectPrimaryButton
        self.didSelectSecondaryButtonHandler = didSelectSecondaryButton
        super.init(frame: .zero)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func didSelectPrimaryButton() {
        didSelectPrimaryButtonHandler?()
    }

    @objc func didSelectSecondaryButton() {
        didSelectSecondaryButtonHandler?()
    }
}

protocol FooterViewActions: NSObjectProtocol {
    func didSelectPrimaryButton()
    func didSelectSecondaryButton()
}
