//
//  ManualEntryErrorView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/31/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class ManualEntryErrorView: UIView {
    
    init(text: String) {
        super.init(frame: .zero)
        let warningIconImageView = UIImageView()
        if #available(iOS 13.0, *) {
            warningIconImageView.image = Image.warning_triangle.makeImage()
                .withTintColor(.textCritical)
        } else {
            assertionFailure()
        }
        warningIconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            warningIconImageView.widthAnchor.constraint(equalToConstant: 14),
            warningIconImageView.heightAnchor.constraint(equalToConstant: 14),
        ])
        
        let errorLabel = UILabel()
        errorLabel.font = .stripeFont(forTextStyle: .body)
        errorLabel.textColor = .textCritical
        errorLabel.numberOfLines = 0
        errorLabel.text = text
        errorLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        let horizontalStackView = UIStackView(
            arrangedSubviews: [
                warningIconImageView,
                errorLabel,
            ]
        )
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 5
        horizontalStackView.alignment = .center
        addAndPinSubview(horizontalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
