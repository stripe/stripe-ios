//
//  DocumentWarmupView.swift
//  StripeIdentity
//
//  Created by Chen Cen on 11/6/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class DocumentWarmupView: UIView {
    struct Styling {
        static let contentInset: NSDirectionalEdgeInsets = .init(
            top: 132,
            leading: 16,
            bottom: 0,
            trailing: 16
        )
        static let warmupIconImageSpacing: CGFloat = 27
        static let warmupTitleSpacing: CGFloat = 12
        static let warmupBodySpacing: CGFloat = 34
        static let acceptIdsContainerPadding: CGFloat = 10
    }

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    private let documentWarmupIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = Image.iconIdFront.makeImage(template: true)
        imageView.tintColor = IdentityUI.iconColor
        return imageView
    }()

    private let documentWarmupTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = IdentityUI.titleFont
        label.accessibilityTraits = [.header]
        label.adjustsFontForContentSizeCategory = true
        label.text = String.Localized.documentFrontWarmupTitle
        return label
    }()

    private let documentWarmupBodyLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = IdentityUI.instructionsFont
        label.adjustsFontForContentSizeCategory = true
        label.text = String.Localized.documentFrontWarmupBody
        label.textColor = IdentityUI.secondaryLabelColor
        return label
    }()

    private let accepedIdContainer: UIView = {
        let uiView = UIView()
        uiView.layer.borderWidth = 1.0
        uiView.layer.borderColor = IdentityUI.separatorColor.cgColor
        uiView.layer.cornerRadius = 12
        return uiView
    }()

    private let acceptedIds: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = IdentityUI.instructionsFont
        label.adjustsFontForContentSizeCategory = true
        label.textColor = IdentityUI.secondaryLabelColor
        return label
    }()

    init(staticContent: StripeAPI.VerificationPageStaticContentDocumentSelectPage) {
        super.init(frame: .zero)
        installViews()
        bindAcceptTypesOfId(allowList: Array(staticContent.idDocumentTypeAllowlist.values))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindAcceptTypesOfId(allowList: [String]) {
        acceptedIds.text = String.Localized.acceptFormsOfId + "\n" + (allowList.map { "• " + $0 }.joined(separator: "\n"))
        accepedIdContainer.addAndPinSubview(
            acceptedIds,
            insets: .init(top: Styling.acceptIdsContainerPadding, leading: Styling.acceptIdsContainerPadding, bottom: Styling.acceptIdsContainerPadding, trailing: Styling.acceptIdsContainerPadding)
        )
    }

    private func installViews() {
        addAndPinSubview(stackView, insets: Styling.contentInset)

        stackView.addArrangedSubview(documentWarmupIconImageView)
        stackView.addArrangedSubview(documentWarmupTitleLabel)
        stackView.addArrangedSubview(documentWarmupBodyLabel)
        stackView.addArrangedSubview(accepedIdContainer)

        stackView.setCustomSpacing(Styling.warmupIconImageSpacing, after: documentWarmupIconImageView)
        stackView.setCustomSpacing(Styling.warmupTitleSpacing, after: documentWarmupTitleLabel)
        stackView.setCustomSpacing(Styling.warmupBodySpacing, after: documentWarmupBodyLabel)

    }

}
