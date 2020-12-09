//
//  STPStackViewWithSeparator.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPStackViewWithSeparator: UIStackView {
    var separatorColor: UIColor = .clear {
        didSet {
            separatorLayer.strokeColor = separatorColor.cgColor
            backgroundView.layer.borderColor = separatorColor.cgColor
        }
    }
    
    override var spacing: CGFloat {
        didSet {
            backgroundView.layer.borderWidth = spacing
            layoutMargins = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        }
    }
    
    var drawBorder: Bool = false {
        didSet {
            isLayoutMarginsRelativeArrangement = drawBorder
            if drawBorder {
                addSubview(backgroundView)
                sendSubviewToBack(backgroundView)
            } else {
                backgroundView.removeFromSuperview()
            }
        }
    }
    
    var borderCornerRadius: CGFloat {
        get {
            return backgroundView.layer.cornerRadius
        }
        set {
            backgroundView.layer.cornerRadius = newValue
        }
    }
    
    @objc
    override public var isUserInteractionEnabled: Bool {
        didSet {
            if isUserInteractionEnabled {
                backgroundView.backgroundColor = STPInputFormColors.backgroundColor
            } else {
                backgroundView.backgroundColor = STPInputFormColors.disabledBackgroundColor
            }
        }
    }
    
    private let separatorLayer = CAShapeLayer()
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = STPInputFormColors.backgroundColor
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()
    
    override public func layoutSubviews() {
        if backgroundView.superview == self {
            sendSubviewToBack(backgroundView)
        }
        super.layoutSubviews()
        if separatorLayer.superlayer == nil {
            layer.addSublayer(separatorLayer)
        }
        separatorLayer.strokeColor = separatorColor.cgColor
        
        let path = UIBezierPath()
        path.lineWidth = spacing
        
        if spacing > 0 {
            // inter-view separators
            let nonHiddenArrangedSubviews = arrangedSubviews.filter({ !$0.isHidden })

            for view in nonHiddenArrangedSubviews {
                
                if axis == .vertical {
                    if view == nonHiddenArrangedSubviews.last {
                        continue
                    }
                    path.move(to: CGPoint(x: view.frame.origin.x, y: view.frame.maxY + 0.5*spacing))
                    path.addLine(to: CGPoint(x: view.frame.maxX, y: view.frame.maxY +  0.5*spacing))
                } else { // .horizontal
                    if view == nonHiddenArrangedSubviews.first {
                        continue
                    }
                    path.move(to: CGPoint(x: view.frame.origin.x - 0.5*spacing, y: view.frame.origin.y))
                    path.addLine(to: CGPoint(x: view.frame.origin.x - 0.5*spacing, y: view.frame.maxY))
                }
                
            }
        }
        
        separatorLayer.path = path.cgPath
    }
}
