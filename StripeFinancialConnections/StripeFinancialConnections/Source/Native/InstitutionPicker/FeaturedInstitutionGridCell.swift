//
//  FeaturedInstitutionGridCellView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/19/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

class FeaturedInstitutionGridCell: UICollectionViewCell {

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        return imageView
    }()

    // only shown if logo fails loading
    private lazy var optionalTitleLabel: UILabel = {
        let label = AttributedLabel(
            font: .body(.small),
            textColor: .textPrimary
        )
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                contentView.layer.borderColor = UIColor.textDisabled.cgColor

                contentView.layer.shadowColor = UIColor.textDisabled.cgColor
                contentView.layer.shadowOffset = .zero
                contentView.layer.shadowOpacity = 0.8
                contentView.layer.shadowRadius = 2
            } else {
                contentView.layer.borderColor = UIColor.borderNeutral.cgColor

                contentView.layer.shadowOpacity = 0  // hide shadow
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .customBackgroundColor
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1

        contentView.addAndPinSubview(
            optionalTitleLabel,
            insets: NSDirectionalEdgeInsets(
                top: 12,
                leading: 12,
                bottom: 12,
                trailing: 12
            )
        )
        optionalTitleLabel.isHidden = true

        contentView.addSubview(logoImageView)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoImageView.widthAnchor.constraint(equalToConstant: 88),
            logoImageView.heightAnchor.constraint(equalToConstant: 40),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        // toggle setter so the coloring applies
        isHighlighted = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Customize

extension FeaturedInstitutionGridCell {

    func customize(with institution: FinancialConnectionsInstitution) {
        optionalTitleLabel.isHidden = true
        logoImageView.isHidden = false
        optionalTitleLabel.text = institution.name

        logoImageView.setImage(
            with: institution.logo?.default,
            completionHandler: { [weak self] didDownloadLogo in
                guard let self = self else {
                    return
                }
                self.logoImageView.isHidden = !didDownloadLogo
                self.optionalTitleLabel.isHidden = !self.logoImageView.isHidden
            }
        )
    }
}
