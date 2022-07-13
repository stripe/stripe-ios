//
//  DataAccessNoticeView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/13/22.
//

import Foundation
import UIKit

final class DataAccessNoticeView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        
        let headerView = addHeaderView()
                
        let blockView = UIView()
        blockView.backgroundColor = UIColor.purple.withAlphaComponent(0.1)
        addSubview(blockView)
        blockView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blockView.heightAnchor.constraint(equalToConstant: 200),
            blockView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            blockView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blockView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blockView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners() // needs to be in `layoutSubviews` to get the correct size for the mask
    }
    
    private func addHeaderView() -> UIView {
        let headerLabel = UILabel()
        headerLabel.numberOfLines = 0
        headerLabel.text = "Data you requested by MERCHANT for the accounts you link:"
        headerLabel.font = .stripeFont(forTextStyle: .heading)
        headerLabel.textColor = UIColor.textPrimary
        headerLabel.textAlignment = .left
        addSubview(headerLabel)
        
        let horizontalPadding: CGFloat = 24
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding),
        ])

        return headerLabel
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
}
