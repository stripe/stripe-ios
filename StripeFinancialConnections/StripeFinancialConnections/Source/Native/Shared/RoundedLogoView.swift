//
//  RoundedLogoView.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-03-10.
//

@_spi(STP) import StripeUICore
import UIKit

func CreateRoundedLogoView(urlString: String) -> UIView {
    let cornerRadius: CGFloat = 16.0
    let shadowContainerView = UIView()
    shadowContainerView.layer.shadowColor = FinancialConnectionsAppearance.Colors.shadow.cgColor
    shadowContainerView.layer.shadowOpacity = 0.18
    shadowContainerView.layer.shadowOffset = CGSize(width: 0, height: 3)
    shadowContainerView.layer.shadowRadius = 5
    shadowContainerView.layer.cornerRadius = cornerRadius
    let radius: CGFloat = 72.0
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = cornerRadius
    imageView.setImage(with: urlString)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: radius),
        imageView.heightAnchor.constraint(equalToConstant: radius),
    ])
    shadowContainerView.addAndPinSubview(imageView)
    return shadowContainerView
}
