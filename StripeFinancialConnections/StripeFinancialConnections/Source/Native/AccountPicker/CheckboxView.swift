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

    private let theme: FinancialConnectionsTheme
    private lazy var checkboxImageView: UIImageView = {
        let checkboxImageView = UIImageView()
        checkboxImageView.contentMode = .scaleAspectFit
        checkboxImageView.image = Image.check.makeImage()
            .withTintColor(theme.primaryColor, renderingMode: .alwaysOriginal)
        return checkboxImageView
    }()

    var isSelected: Bool = false {
        didSet {
            checkboxImageView.isHidden = !isSelected
        }
    }

    init(theme: FinancialConnectionsTheme) {
        self.theme = theme
        super.init(frame: .zero)
        addAndPinSubview(checkboxImageView)
        isSelected = false  // fire off setter to draw
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
