//
//  ConsentLogoView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 12/22/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class ConsentLogoView: UIView {

    init(merchantLogo: [String]) {
        super.init(frame: .zero)
        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 16.0
        horizontalStackView.alignment = .center
        // display one logo
        if merchantLogo.isEmpty {
            let imageView = UIImageView(image: Image.stripe_logo.makeImage(template: true))
            imageView.tintColor = .textBrand
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 60),
                imageView.heightAnchor.constraint(equalToConstant: 25),
            ])
            horizontalStackView.addArrangedSubview(imageView)
        }
        // display multiple logos
        else {
            for i in 0..<merchantLogo.count {
                let urlString = merchantLogo[i]
                horizontalStackView.addArrangedSubview(
                    CreateCircularLogoView(urlString: urlString)
                )

                let isLastLogo = (i == merchantLogo.count - 1)
                if !isLastLogo {
                    horizontalStackView.addArrangedSubview(CreateEllipsisView())
                }
            }
        }
        addAndPinSubview(horizontalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateCircularLogoView(urlString: String) -> UIView {
    let radius: CGFloat = 40.0
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = radius / 2.0
    imageView.setImage(with: urlString)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: radius),
        imageView.heightAnchor.constraint(equalToConstant: radius),
    ])
    return imageView
}

private func CreateEllipsisView() -> UIView {
    let imageView = UIImageView(image: Image.ellipsis.makeImage())
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: 16),
        imageView.heightAnchor.constraint(equalToConstant: 4),
    ])
    return imageView
}
