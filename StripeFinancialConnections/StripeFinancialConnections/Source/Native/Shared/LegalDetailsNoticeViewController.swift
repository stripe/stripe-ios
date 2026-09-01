//
//  LegalDetailsNoticeViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/3/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class LegalDetailsNoticeViewController: SheetViewController {

    private let legalDetailsNotice: FinancialConnectionsLegalDetailsNotice
    private let appearance: FinancialConnectionsAppearance
    private let didSelectUrl: (URL) -> Void

    init(
        legalDetailsNotice: FinancialConnectionsLegalDetailsNotice,
        appearance: FinancialConnectionsAppearance,
        didSelectUrl: @escaping (URL) -> Void
    ) {
        self.legalDetailsNotice = legalDetailsNotice
        self.appearance = appearance
        self.didSelectUrl = didSelectUrl
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup(
            withContentView: PaneLayoutView.createContentView(
                iconView: appearance.colors == .link
                    ? nil
                    : RoundedIconView(
                        image: .imageUrl(legalDetailsNotice.icon?.default),
                        style: .circle,
                        appearance: appearance
                    ),
                title: legalDetailsNotice.title,
                subtitle: legalDetailsNotice.subtitle,
                contentView: CreateMultiLinkView(
                    linkItems: legalDetailsNotice.body.links,
                    appearance: appearance,
                    didSelectURL: didSelectUrl
                ),
                isSheet: true,
                appearance: appearance
            ),
            footerView: PaneLayoutView.createFooterView(
                primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                    title: legalDetailsNotice.cta,
                    action: { [weak self] in
                        guard let self = self else { return }
                        self.dismiss(animated: true)
                    }
                ),
                secondaryButtonConfiguration: nil,
                topText: legalDetailsNotice.disclaimer,
                appearance: appearance,
                didSelectURL: didSelectUrl
            ).footerView
        )
    }
}

private func CreateMultiLinkView(
    linkItems: [FinancialConnectionsLegalDetailsNotice.Body.Link],
    appearance: FinancialConnectionsAppearance,
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    if appearance.colors == .link {
        return CreateLinkThemeMultiLinkView(
            linkItems: linkItems,
            appearance: appearance,
            didSelectURL: didSelectURL
        )
    }

    let verticalStackView = HitTestStackView()
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 16
    verticalStackView.addArrangedSubview(CreateSeparatorView())
    linkItems.forEach { linkItem in
        verticalStackView.addArrangedSubview(
            CreateSingleLinkView(
                title: linkItem.title,
                content: linkItem.content,
                appearance: appearance,
                didSelectURL: didSelectURL
            )
        )
        verticalStackView.addArrangedSubview(CreateSeparatorView())
    }
    return verticalStackView
}

// Link DS 3.0: each link is rendered as a whole-row-tappable list item inside a
// grey card, with the URL extracted from the markdown embedded in `title`/`content`
// since the model has no dedicated URL field.
private func CreateLinkThemeMultiLinkView(
    linkItems: [FinancialConnectionsLegalDetailsNotice.Body.Link],
    appearance: FinancialConnectionsAppearance,
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    let verticalStackView = UIStackView()
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 0

    linkItems.enumerated().forEach { index, linkItem in
        if index > 0 {
            verticalStackView.addArrangedSubview(CreateLinkThemeSeparatorView())
        }
        let url = ExtractLinkURL(fromTitle: linkItem.title, content: linkItem.content)
        verticalStackView.addArrangedSubview(
            LinkNoticeRowView(
                title: linkItem.title.extractLinks().linklessString,
                content: linkItem.content?.extractLinks().linklessString,
                appearance: appearance,
                didSelect: {
                    if let url = url {
                        didSelectURL(url)
                    }
                }
            )
        )
    }

    let cardView = UIView()
    cardView.backgroundColor = appearance.colors.iconBackground
    cardView.layer.cornerRadius = 16
    cardView.layer.masksToBounds = true
    cardView.addAndPinSubview(verticalStackView)
    return cardView
}

private func ExtractLinkURL(fromTitle title: String, content: String?) -> URL? {
    if let link = title.extractLinks().links.first, let url = URL(string: link.urlString) {
        return url
    }
    if let content = content, let link = content.extractLinks().links.first, let url = URL(string: link.urlString) {
        return url
    }
    return nil
}

private func CreateLinkThemeSeparatorView() -> UIView {
    let container = UIView()
    let separatorView = UIView()
    separatorView.backgroundColor = FinancialConnectionsAppearance.Colors.dividerOnCard
    separatorView.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(separatorView)
    NSLayoutConstraint.activate([
        separatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.nativeScale),
        separatorView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
        separatorView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        separatorView.topAnchor.constraint(equalTo: container.topAnchor),
        separatorView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
    return container
}

private final class LinkNoticeRowView: UIView {
    private let didSelect: () -> Void

    init(
        title: String,
        content: String?,
        appearance: FinancialConnectionsAppearance,
        didSelect: @escaping () -> Void
    ) {
        self.didSelect = didSelect
        super.init(frame: .zero)

        let titleLabel = AttributedLabel(
            font: .label(.large),
            textColor: appearance.colors.textPrimary
        )
        titleLabel.setText(title)

        let labelStackView = UIStackView(arrangedSubviews: [titleLabel])
        labelStackView.axis = .vertical
        labelStackView.spacing = 0
        if let content = content {
            let contentLabel = AttributedLabel(
                font: .label(.medium),
                textColor: appearance.colors.textTertiary
            )
            contentLabel.setText(content)
            labelStackView.addArrangedSubview(contentLabel)
        }

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: config))
        chevronImageView.tintColor = FinancialConnectionsAppearance.Colors.textSubdued
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.setContentHuggingPriority(.required, for: .horizontal)
        chevronImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let horizontalStackView = UIStackView(arrangedSubviews: [labelStackView, chevronImageView])
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 12
        horizontalStackView.alignment = .center
        horizontalStackView.isLayoutMarginsRelativeArrangement = true
        horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        addAndPinSubview(horizontalStackView)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        addGestureRecognizer(tapGestureRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapView() {
        didSelect()
    }
}

private func CreateSingleLinkView(
    title: String,
    content: String?,
    appearance: FinancialConnectionsAppearance,
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    let verticalLabelStackView = HitTestStackView()
    verticalLabelStackView.axis = .vertical
    verticalLabelStackView.spacing = 0

    let linkColor: UIColor = appearance.colors == .link
        ? FinancialConnectionsAppearance.Colors.textDefault
        : appearance.colors.textAction
    let titleLabelFont: FinancialConnectionsFont = .label(.largeEmphasized)
    let titleLabel = AttributedTextView(
        font: titleLabelFont,
        boldFont: titleLabelFont,
        linkFont: titleLabelFont,
        textColor: FinancialConnectionsAppearance.Colors.textDefault,
        linkColor: linkColor,
        showLinkUnderline: false
    )
    titleLabel.setText(title, action: didSelectURL)
    verticalLabelStackView.addArrangedSubview(titleLabel)

    if let content = content {
        let contentFont: FinancialConnectionsFont = .label(.medium)
        let contentLabel = AttributedTextView(
            font: contentFont,
            boldFont: contentFont,
            linkFont: contentFont,
            textColor: FinancialConnectionsAppearance.Colors.textSubdued,
            linkColor: linkColor,
            showLinkUnderline: false
        )
        contentLabel.setText(content, action: didSelectURL)
        verticalLabelStackView.addArrangedSubview(contentLabel)
    }

    return verticalLabelStackView
}

private func CreateSeparatorView() -> UIView {
    let separatorView = UIView()
    separatorView.backgroundColor = FinancialConnectionsAppearance.Colors.borderNeutral
    separatorView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        separatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.nativeScale)
    ])
    return separatorView
}
