//
//  CheckmarkView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/3/24.
//

import Foundation
import UIKit

class CheckmarkView: UIView {
    
    private let checkmarkColor: UIColor = .systemBlue
    private let lineWidth: CGFloat = 2
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 16, height: 16)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor(checkmarkColor.cgColor)
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 3, y: 8))
        path.addLine(to: CGPoint(x: 7, y: 12))
        path.addLine(to: CGPoint(x: 13, y: 4))
        
        context.addPath(path.cgPath)
        context.strokePath()
    }
}
