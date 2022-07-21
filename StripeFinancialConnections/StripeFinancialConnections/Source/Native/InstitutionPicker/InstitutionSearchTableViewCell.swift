//
//  InstitutionSearchTableViewCell.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/21/22.
//

import Foundation
import UIKit

final class InstitutionSearchTableViewCell: UITableViewCell {
    
    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.layer.cornerRadius = 6
        iconImageView.backgroundColor = .borderNeutral
        return iconImageView
    }()
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .stripeFont(forTextStyle: .bodyEmphasized)
        titleLabel.textColor = .textPrimary
        return titleLabel
    }()
    private lazy var subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.font = .stripeFont(forTextStyle: .captionTight)
        subtitleLabel.textColor = .textDisabled
        return subtitleLabel
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(iconImageView)
        
        let labelStackView = UIStackView(
            arrangedSubviews: [
                titleLabel,
                subtitleLabel,
            ]
        )
        labelStackView.axis = .vertical
        labelStackView.spacing = 2
        contentView.addSubview(labelStackView)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 36),
            iconImageView.heightAnchor.constraint(equalToConstant: 36),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            labelStackView.leftAnchor.constraint(equalTo: iconImageView.rightAnchor, constant: 12),
            
            labelStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            labelStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
        ])
        
        self.selectedBackgroundView = CreateSelectedBackgroundView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateSelectedBackgroundView() -> UIView {
    let selectedBackgroundView = UIView()
    selectedBackgroundView.backgroundColor = .backgroundContainer
    
    let topSeparatorView = UIView()
    topSeparatorView.backgroundColor = .borderNeutral
    let bottomSeparatorView = UIView()
    bottomSeparatorView.backgroundColor = .borderNeutral
    selectedBackgroundView.addSubview(topSeparatorView)
    selectedBackgroundView.addSubview(bottomSeparatorView)
    
    topSeparatorView.translatesAutoresizingMaskIntoConstraints = false
    bottomSeparatorView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        topSeparatorView.topAnchor.constraint(equalTo: selectedBackgroundView.topAnchor),
        topSeparatorView.leadingAnchor.constraint(equalTo: selectedBackgroundView.leadingAnchor),
        topSeparatorView.trailingAnchor.constraint(equalTo: selectedBackgroundView.trailingAnchor),
        topSeparatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.nativeScale),
        
        bottomSeparatorView.bottomAnchor.constraint(equalTo: selectedBackgroundView.bottomAnchor),
        bottomSeparatorView.leadingAnchor.constraint(equalTo: selectedBackgroundView.leadingAnchor),
        bottomSeparatorView.trailingAnchor.constraint(equalTo: selectedBackgroundView.trailingAnchor),
        bottomSeparatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.nativeScale),
    ])
    
    return selectedBackgroundView
}

// MARK: - Customize

extension InstitutionSearchTableViewCell {
    
    func customize(with institution: FinancialConnectionsInstitution) {
        // TODO(kgaidis): set `iconImageView` when we get icons
        titleLabel.text = institution.name
        subtitleLabel.text = institution.url
    }
}
