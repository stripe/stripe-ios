//
//  FeaturedInstitutionGridCellView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/19/22.
//

import Foundation
import UIKit

class FeaturedInstitutionGridCell: UICollectionViewCell {
    
    // TODO(kgaidis): temporary until we get images working
    private lazy var temporaryLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textPrimary
        label.font = .stripeFont(forTextStyle: .detail)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        contentView.layer.borderColor = UIColor.borderNeutral.cgColor
        contentView.layer.borderWidth = 1
        
        contentView.addSubview(temporaryLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        temporaryLabel.frame = contentView.bounds.inset(by: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
    }
}

// MARK: - Customize

extension FeaturedInstitutionGridCell {
    
    func customize(with institution: FinancialConnectionsInstitution) {
        temporaryLabel.text = institution.name
    }
}
