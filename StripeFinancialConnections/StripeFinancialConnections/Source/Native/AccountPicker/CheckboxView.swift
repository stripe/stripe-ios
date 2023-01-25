//
//  CheckboxView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/10/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class CheckboxView: UIView {

    private let checkboxImageView: UIImageView = {
        let checkboxImageView = UIImageView()
        checkboxImageView.contentMode = .scaleAspectFit
        checkboxImageView.image = Image.check.makeImage()
            .withTintColor(.customBackgroundColor, renderingMode: .alwaysOriginal)
        return checkboxImageView
    }()

    var isSelected: Bool = false {
        didSet {
            checkboxImageView.isHidden = !isSelected
            layer.cornerRadius = 6
            if isSelected {
                backgroundColor = .textBrand
                layer.borderWidth = 0
                layer.borderColor = UIColor.clear.cgColor
            } else {
                backgroundColor = .clear
                layer.borderWidth = 1
                layer.borderColor = UIColor.borderNeutral.cgColor
            }
        }
    }

    init() {
        super.init(frame: .zero)
        isSelected = false  // fire off setter to draw
        addSubview(checkboxImageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        let checkmarkSize = CGSize(width: 12, height: 12)
        checkboxImageView.frame = CGRect(
            x: bounds.midX - checkmarkSize.width / 2,
            y: bounds.midY - checkmarkSize.height / 2,
            width: checkmarkSize.width,
            height: checkmarkSize.height
        )
    }
}
