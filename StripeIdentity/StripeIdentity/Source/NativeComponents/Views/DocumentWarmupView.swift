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

    private let acceptedIds: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = IdentityUI.instructionsFont
        label.adjustsFontForContentSizeCategory = true
        label.textColor = IdentityUI.textColor
        return label
    }()

    init(staticContent: StripeAPI.VerificationPageStaticContentDocumentSelectPage) {
        super.init(frame: .zero)
        installViews()
        bindAcceptTypesOfId(allowList: Array(staticContent.idDocumentTypeAllowlist.keys.compactMap { value in
            if value == "driving_license" {
                return String.Localized.driverLicense
            } else if value == "id_card" {
                return String.Localized.governmentIssuedId
            } else if value == "passport" {
                return String.Localized.passport
            } else {
                return nil
            }
        }))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindAcceptTypesOfId(allowList: [String]) {
        acceptedIds.text = String.Localized.acceptFormsOfId + " " + (allowList.map { $0 }.joined(separator: ", ")) + "."
    }

    private func installViews() {
        addAndPinSubview(stackView, insets: Styling.contentInset)

        stackView.addArrangedSubview(documentWarmupIconImageView)
        stackView.addArrangedSubview(documentWarmupTitleLabel)
        stackView.addArrangedSubview(acceptedIds)

        stackView.setCustomSpacing(Styling.warmupIconImageSpacing, after: documentWarmupIconImageView)
        stackView.setCustomSpacing(Styling.warmupTitleSpacing, after: documentWarmupTitleLabel)

    }

}
