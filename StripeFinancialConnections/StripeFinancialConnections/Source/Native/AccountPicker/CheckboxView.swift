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

    private let appearance: FinancialConnectionsAppearance
    private lazy var checkboxImageView: UIImageView = {
        let checkboxImageView = UIImageView()
        checkboxImageView.contentMode = .scaleAspectFit
        checkboxImageView.image = Image.check.makeImage()
            .withTintColor(appearance.colors.primary, renderingMode: .alwaysOriginal)
        return checkboxImageView
    }()

    var isSelected: Bool = false {
        didSet {
            checkboxImageView.isHidden = !isSelected
        }
    }

    init(appearance: FinancialConnectionsAppearance) {
        self.appearance = appearance
        super.init(frame: .zero)
        addAndPinSubview(checkboxImageView)
        isSelected = false  // fire off setter to draw
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
