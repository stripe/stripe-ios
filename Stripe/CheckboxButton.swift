//
//  CheckboxButton.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 12/11/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class CheckboxButton: UIButton {
    
    override func draw(_ rect: CGRect) {
        
        let borderRectWidth = min(16, rect.width - 2)
        let borderRectHeight = min(16, rect.height - 2)
        let borderRect = CGRect(x: max(0, rect.midX - 0.5*borderRectWidth), y: max(0, rect.midY - 0.5*borderRectHeight), width: borderRectWidth, height: borderRectHeight)
        
        let borderPath = UIBezierPath(roundedRect: borderRect, cornerRadius: 3)
        borderPath.lineWidth = 1
        if isUserInteractionEnabled {
            STPInputFormColors.backgroundColor.setFill()
        } else {
            STPInputFormColors.disabledBackgroundColor.setFill()
        }
        borderPath.fill()
        STPInputFormColors.outlineColor.setStroke()
        borderPath.stroke()
        
        if isSelected {
            let checkmarkPath = UIBezierPath()
            checkmarkPath.move(to: CGPoint(x: borderRect.minX + 4, y: borderRect.minY + 6))
            checkmarkPath.addLine(to: CGPoint(x: borderRect.minX + 4 + 4, y: borderRect.minY + 6 + 4))
            checkmarkPath.addLine(to: CGPoint(x: borderRect.maxX + 1, y: borderRect.minY - 1))
            checkmarkPath.lineCapStyle = .round
            checkmarkPath.lineWidth = 2
            if isUserInteractionEnabled {
                STPInputFormColors.textColor.setStroke()
            } else {
                STPInputFormColors.disabledTextColor.setStroke()
            }
            checkmarkPath.stroke()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 20, height: 20)
    }
    
    static let touchableSize: CGFloat = 42

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        var pointInside = super.point(inside: point, with: event)
        if !pointInside,
           isEnabled,
           !isHidden,
           (bounds.width < CheckboxButton.touchableSize || bounds.height < CheckboxButton.touchableSize) {
            // Make sure that we intercept touch events even outside our bounds if they are within the
            // minimum touch area. Otherwise this button is too hard to tap
            let expandedBounds = bounds.insetBy(dx: min(bounds.width - CheckboxButton.touchableSize, 0), dy: min(bounds.height - CheckboxButton.touchableSize, 0))
            pointInside = expandedBounds.contains(point)
        }
        return pointInside
    }
    
}
