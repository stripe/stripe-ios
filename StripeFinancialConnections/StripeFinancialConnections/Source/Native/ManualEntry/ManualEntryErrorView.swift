//
//  ManualEntryErrorView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/31/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class ManualEntryErrorView: UIView {

    init(text: String) {
        super.init(frame: .zero)
        let errorLabelFont = UIFont.stripeFont(forTextStyle: .body)
        let warningIconWidthAndHeight: CGFloat = 14
        let warningIconInsets = (errorLabelFont.lineHeight - warningIconWidthAndHeight) / 2
        let warningIconImageView = UIImageView()
        warningIconImageView.image = Image.warning_triangle.makeImage()
            .withTintColor(.textCritical)
            // Align the icon to the center of the first line.
            //
            // UIStackView does not do a great job of doing this
            // automatically.
            .withAlignmentRectInsets(
                UIEdgeInsets(top: -warningIconInsets, left: 0, bottom: warningIconInsets, right: 0)
            )
        warningIconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            warningIconImageView.widthAnchor.constraint(equalToConstant: warningIconWidthAndHeight),
            warningIconImageView.heightAnchor.constraint(equalToConstant: warningIconWidthAndHeight),
        ])

        let errorLabel = UILabel()
        errorLabel.font = errorLabelFont
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
        horizontalStackView.spacing = 6
        // align icon + text to the top
        horizontalStackView.alignment = .top
        addAndPinSubview(horizontalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
