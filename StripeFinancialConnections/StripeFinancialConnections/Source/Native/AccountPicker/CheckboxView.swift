//
//  CheckboxView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/10/22.
//

import Foundation
import UIKit

final class CheckboxView: UIView {
    
    var isSelected: Bool = false {
        didSet {
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
        isSelected = false // fire off setter to draw
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
