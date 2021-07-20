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
 Returns a rounded, lightly shadowed view with a thin border.
 You can put e.g., text fields inside it.
 */
class ContainerView: UIView {
    enum Style {
        case `default`
        /// Red border
        case `error`
    }
    
    // MARK: - Properties
    
    var style: Style = .default {
        didSet {
            updateUI()
        }
    }
    override var isUserInteractionEnabled: Bool {
        didSet {
            updateUI()
        }
    }
    let insets: NSDirectionalEdgeInsets = .init(top: 4, leading: 14, bottom: 6, trailing: 14)

    // MARK: - Initializers

    init(views: [UIView]) {
        super.init(frame: .zero)
        // TODO: Support multiple views
        addAndPinSubview(
            views.first!,
            insets: insets
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
    
    // MARK: - Overrides

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath  // To improve performance
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateUI()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, self.point(inside: point, with: event) else {
            return nil
        }
        
        // Clamp the point to be within our inset bounds
        let point = CGPoint(
            x: min(max(insets.leading, point.x), bounds.width - insets.trailing - 1),
            y: min(max(insets.top, point.y), bounds.height - insets.bottom - 1)
        )

        for subview in subviews.reversed() {
            let convertedPoint = subview.convert(point, from: self)
            if let candidate = subview.hitTest(convertedPoint, with: event) {
                return candidate
            }
        }
        return nil
    }

    // MARK: - Internal methods

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
        
        if isUserInteractionEnabled || isDarkMode() {
            backgroundColor = PaymentSheetUI.backgroundColor
        } else {
            backgroundColor = CompatibleColor.tertiarySystemGroupedBackground
        }
    }
}

// MARK: - EventHandler

extension ContainerView: EventHandler {
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            isUserInteractionEnabled = true
        case .shouldDisableUserInteraction:
            isUserInteractionEnabled = false
        }
    }
}
