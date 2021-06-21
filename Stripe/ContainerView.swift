//
//  ContainerView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 Returns a rounded, lightly shadowed transparent view with a thin border.
 You can put e.g., text fields inside it.
 */
class ContainerView: UIView {
    enum Style {
        case `default`
        /// Red border
        case `error`
    }
    var style: Style = .default {
        didSet {
            updateUI()
        }
    }

    init(views: [UIView]) {
        super.init(frame: .zero)
        // TODO: Support multiple views
        addAndPinSubview(
            views.first!,
            insets: NSDirectionalEdgeInsets(top: 2, leading: 14, bottom: 2, trailing: 14)
        )
        backgroundColor = PaymentSheetUI.backgroundColor
        layer.cornerRadius = PaymentSheetUI.defaultButtonCornerRadius
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowRadius = 4
        layer.borderWidth = 1
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath  // To improve performance
    }

    func updateUI() {
        let borderColor: UIColor = {
            switch style {
            case .default:
                return CompatibleColor.separator
            case .error:
                return UIColor.systemRed
            }
        }()

        layer.borderColor = borderColor.cgColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateUI()
    }
}
