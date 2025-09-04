//
//  LinkFullConsent-ScopesView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/24/25.
//

@_spi(STP) import StripeUICore
import UIKit

final class LinkFullConsentScopesView: UIView {
    private static let iconContainerSize: CGFloat = 36
    private static let iconSize: CGFloat = 16

    typealias Scope = LinkConsentDataModel.ConsentPane.ScopesSection.Scope

    private let scopes: [Scope]

    private lazy var scopesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = LinkUI.contentSpacing
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .insets(amount: LinkUI.contentSpacing)
        return stackView
    }()

    init(scopes: [Scope]) {
        self.scopes = scopes
        super.init(frame: .zero)
        setupUI()
        setupScopes()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .linkSurfacePrimary
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.linkSurfaceTertiary.cgColor
        layer.cornerRadius = LinkUI.cornerRadius

        addAndPinSubview(scopesStackView)
    }

    private func setupScopes() {
        for scope in scopes {
            // Only show scope if it has both icon and header
            guard let icon = scope.icon, let iconUrl = URL(string: icon.defaultUrl), let header = scope.header else {
                continue
            }
            let scopeView = createScopeView(iconUrl: iconUrl, header: header, description: scope.description)
            scopesStackView.addArrangedSubview(scopeView)
        }
    }

    private func createScopeView(iconUrl: URL, header: String, description: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let iconContainerView = UIView()
        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        iconContainerView.backgroundColor = .linkSurfaceTertiary
        iconContainerView.layer.cornerRadius = LinkUI.cornerRadius
        iconContainerView.widthAnchor.constraint(equalToConstant: Self.iconContainerSize).isActive = true
        iconContainerView.heightAnchor.constraint(equalToConstant: Self.iconContainerSize).isActive = true

        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .linkTextPrimary
        iconImageView.setImageAsTemplate(from: iconUrl, placeholder: Image.icon_lock)

        iconContainerView.addSubview(iconImageView)

        let textStackView = UIStackView()
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.axis = .vertical
        textStackView.spacing = 2
        textStackView.alignment = .fill

        let headerLabel = UILabel()
        headerLabel.text = header
        headerLabel.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        headerLabel.textColor = .linkTextPrimary
        headerLabel.numberOfLines = 0
        textStackView.addArrangedSubview(headerLabel)

        if !description.isEmpty {
            let descriptionLabel = UILabel()
            descriptionLabel.text = description
            descriptionLabel.font = LinkUI.font(forTextStyle: .caption)
            descriptionLabel.textColor = .linkTextSecondary
            descriptionLabel.numberOfLines = 0
            textStackView.addArrangedSubview(descriptionLabel)
        }

        containerView.addSubview(iconContainerView)
        containerView.addSubview(textStackView)

        NSLayoutConstraint.activate([
            iconContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconContainerView.topAnchor.constraint(equalTo: containerView.topAnchor),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: Self.iconSize),

            textStackView.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: LinkUI.contentSpacing),
            textStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            textStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        return containerView
    }

    #if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = UIColor.linkSurfaceTertiary.cgColor
        }
    }
    #endif
}

private extension UIImageView {
    func setImageAsTemplate(from url: URL, placeholder: Image) {
        image = placeholder.makeImage(template: true)
        Task {
            guard let image = try? await DownloadManager.sharedManager.downloadImage(url: url) else {
                return
            }
            await MainActor.run {
                self.image = image.withRenderingMode(.alwaysTemplate)
            }
        }
    }
}
